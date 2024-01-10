class Collective < ApplicationRecord
  validates :slug, presence: true

  has_many :collective_projects, dependent: :destroy
  has_many :projects, through: :collective_projects

  has_many :transactions, dependent: :destroy

  scope :with_repository, -> { where.not(repository: nil) }

  def self.sync_least_recently_synced
    Collective.where(last_synced_at: nil).or(Collective.where("last_synced_at < ?", 1.day.ago)).order('last_synced_at asc nulls first').limit(500).each do |collective|
      collective.sync_async
    end
  end

  def to_s
    name
  end

  def to_param
    slug
  end

  def html_url
    "https://opencollective.com/#{slug}"
  end

  def self.tags
    pluck(Arel.sql("unnest(tags)")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def project_topics
    projects.pluck(Arel.sql("repository -> 'topics'")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def sync_async
    SyncCollectiveWorker.perform_async(id)
  end

  def fetch_from_open_collective_graphql
    query = <<~GRAPHQL
      query {
        collective(slug: "#{slug}") {
          name
          description
          slug
          website
          githubHandle
          twitterHandle
          currency
        }
      }
    GRAPHQL

    response = Faraday.post("https://opencollective.com/api/graphql/v2?personalToken=#{ENV['OPEN_COLLECTIVE_API_KEY']}", { query: query }.to_json, { 'Content-Type' => 'application/json' })
    JSON.parse(response.body)['data']['collective']
  rescue
      nil
  end

  def map_from_open_collective_graphql
    data = fetch_from_open_collective_graphql
    return if data.nil?

    {
      uuid: data['id'],
      name: data['name'],
      description: data['description'],
      website: data['website'],
      github: data['githubHandle'],
      twitter: data['twitterHandle'],
      currency: data['currency'],
      tags: data['tags'],
      repository_url: data['repositoryUrl'],
      social_links: data['socialLinks'],
      last_synced_at: Time.now
    }
  end

  def sync
    update(map_from_open_collective_graphql)
    load_projects
  rescue
    puts "Error syncing #{url}"
  end

  def load_projects
    # .each do |link|
    #   project = Project.find_or_create_by(url: link[:url])
    #   project.sync_async if project.last_synced_at.nil?
    #   collective_project = collective_projects.find_or_create_by(project_id: project.id)
    #   collective_project.update(name: link[:name], description: link[:description], category: link[:category], sub_category: link[:sub_category])
    # end
  end  

  def self.discover
    first_page = load_osc_projects
    total_count = first_page['data']['account']['memberOf']['totalCount']
    puts "Total count: #{total_count}"
    offset = 0
    while offset < total_count
      puts "Loading page #{offset}"
      page = load_osc_projects(offset: offset)
      page['data']['account']['memberOf']['nodes'].each do |node|
        puts "Loading #{node['account']['slug']}"
        collective = Collective.find_or_create_by(slug: node['account']['slug'])
        collective.sync_async if collective.last_synced_at.nil?
      end
      offset += 1000
    end
  end

  def self.load_osc_projects(offset: 0)
    graphql_url = "https://opencollective.com/api/graphql/v2?personalToken=#{ENV['OPEN_COLLECTIVE_API_KEY']}"
    
    query = <<~GRAPHQL
      query ContributionsSection(
        $orderBy: OrderByInput
      ) {
        account(slug: "opensource") {
          memberOf(
            limit: 1000
            offset: #{offset}
            role: HOST
            accountType: COLLECTIVE
            orderByRoles: true
            isApproved: true
            isArchived: false
            orderBy: $orderBy
          ) {
            offset
            limit
            totalCount
            nodes {
              id
              since
              account {
                id
                slug
              }
            }
          }
        }
      }
    GRAPHQL

    conn = Faraday.new(url: graphql_url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    resp = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { query: query }.to_json
    end

    json = JSON.parse(resp.body)
  end

  def sync_transactions
    first_page = fetch_transactions_from_graphql
    total_count = first_page['data']['transactions']['totalCount']
    puts "Total count: #{total_count}"
    offset = 0
    while offset < total_count
      puts "Loading transactions #{offset}"
      page = fetch_transactions_from_graphql(offset: offset)
      transactions = page['data']['transactions']['nodes'].map do |node|
        {
          collective_id: id,
          uuid: node['uuid'],
          amount: node['amount']['value'],
          net_amount: node['netAmount']['value'],
          kind: node['type'],
          currency: node['amount']['currency'],
          account: node['type'] == 'DEBIT' ? node['toAccount']['slug'] : node['fromAccount']['slug'],
          created_at: node['createdAt'],
          description: node['description']
        }
      end
      Transaction.upsert_all(transactions, unique_by: :uuid)
      offset += 1000
    end
  end

  def fetch_transactions_from_graphql(offset: 0)
    graphql_url = "https://opencollective.com/api/graphql/v2?personalToken=#{ENV['OPEN_COLLECTIVE_API_KEY']}"

    query = <<~GRAPHQL
      query Transactions(
        $account: [AccountReferenceInput!]
        $limit: Int
        $offset: Int
      ) {
        transactions(
          account: $account
          limit: $limit
          offset: $offset
        ) {
          offset
          limit
          totalCount
          nodes {
            uuid
            amount {
              value
              currency
            }
            description
            netAmount {
              value
              currency
            }            
            createdAt
            type
            toAccount {
              slug
            }
            fromAccount {
              slug
            }
          }
        }
      }
    GRAPHQL

    conn = Faraday.new(url: graphql_url) do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    resp = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { query: query, variables: { account: { slug: slug }, limit: 1000, offset: offset } }.to_json
    end

    json = JSON.parse(resp.body)
  end

  def total_donations
    transactions.donations.sum(:net_amount) + transactions.host_fees.sum(:net_amount)
  end

  def total_expenses
    transactions.expenses.sum(:net_amount)
  end
end