class Collective < ApplicationRecord
  validates :slug, presence: true

  has_many :collective_projects, dependent: :destroy
  has_many :projects, through: :collective_projects
  has_many :issues, through: :projects

  has_many :transactions, dependent: :destroy

  scope :with_transactions, -> { where.not(transactions_count: 0) }

  scope :with_projects, -> { where.not(projects_count: 0) }
  
  scope :with_owner, -> { where.not(owner: nil) }
  scope :with_org_owner, -> { with_owner.where("owner ->> 'kind' = 'organization'") }
  scope :with_user_owner, -> { with_owner.where("owner ->> 'kind' = 'user'") }


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

  def icon_url(size: 40)
    "https://images.opencollective.com/#{slug}/logo/#{size}.png"
  end

  def self.tags
    pluck(Arel.sql("unnest(tags)")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def project_topics
    projects.pluck(Arel.sql("repository -> 'topics'")).flatten.reject(&:blank?).group_by(&:itself).transform_values(&:count).sort_by{|k,v| v}.reverse
  end

  def last_project_activity_at
    projects.with_repository.select{|p| p.last_activity_at.present? }.sort_by(&:last_activity_at).last.try(:last_activity_at)
  end

  def inactive?
    return false if last_project_activity_at.nil?
    last_project_activity_at < 1.year.ago
  end

  def archived?
    projects.with_repository.all?{|p| p.archived? }
  end

  def no_license?
    projects.with_repository.all?{|p| p.no_license? }
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
          type
          socialLinks {
            type
            url
          }
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
      kind: data['type'],
      last_synced_at: Time.now
    }
  end

  def sync
    updated_attrs = map_from_open_collective_graphql
    update(updated_attrs) if updated_attrs.present?
    load_projects
    sync_transactions
    sync_owner
    ping_owner
  rescue
    puts "Error syncing #{slug}"
  end

  def ping_owner
    return unless project_url.present?
    return unless project_org?
    ping_owner_url = "https://repos.ecosyste.ms/api/v1/hosts/#{project_host}/owners/#{project_owner}/ping"
    Faraday.get(ping_owner_url) rescue nil
  end

  def fetch_owner
    return unless project_owner.present?
    
    conn = Faraday.new(url: "https://repos.ecosyste.ms") do |faraday|
      faraday.response :follow_redirects
      faraday.adapter Faraday.default_adapter
    end

    resp = conn.get("/api/v1/hosts/#{project_host}/owners/#{project_owner}")
    return unless resp.status == 200
    JSON.parse(resp.body)
  rescue => e
    puts "Error fetching owner for #{slug}: #{e.message}"
    nil
  end

  def sync_owner
    owner = fetch_owner
    return unless owner.present?
    update(owner: owner) 
  end

  def website
    return read_attribute(:website) if read_attribute(:website).present?
    (social_links || {}).select{|x| ['WEBSITE'].include? x['type']}.first.try(:[], 'url') || ''
  end

  def project_url
    return "https://github.com/#{github}" if github.present?
    return repository_url if repository_url.present?
    social_link =(social_links || {}).select{|x| ['GITHUB', 'GITLAB', 'GIT'].include? x['type']}.first.try(:[], 'url')
    return social_link if social_link.present?

    # check if website is a github repo
    return website if website.match(/github.com\/(.*)/)

    # check if website is a github pages site
    return github_pages_to_repo_url(website) if website.match(/github.io/)
    
    # check if website is a gitlab repo
    return website if website.match(/gitlab.com\/(.*)/)

    nil
  end

  def github_pages_to_repo_url(github_pages_url)
    match = github_pages_url.chomp('/').match(/https?:\/\/(.+)\.github\.io(\/(.+))?/)
    return nil unless match

    username = match[1]
    repo_name = match[3]

    "https://github.com/#{username}#{repo_name ? "/#{repo_name}" : ""}"
  end

  def project_org?
    case URI.parse(project_url).host
    when 'github.com'
      project_url.match(/github.com\/(.*)/)[1].split('/').count == 1
    when 'gitlab.com'
      project_url.match(/gitlab.com\/(.*)/)[1].split('/').count == 1
    when 'codeberg.org'
      project_url.match(/codeberg.org\/(.*)/)[1].split('/').count == 1
    else
      false
    end
  end

  def project_host
    return unless project_url.present?
    host = URI.parse(project_url).host
    host = 'GitHub' if host == 'github.com'
    host
  end

  def project_owner
    return unless project_url.present?
    URI.parse(project_url).path.split('/').reject(&:blank?).first
  end

  def load_projects
    return if project_url.nil?
    if project_org?
      page = 1
      loop do
        resp = Faraday.get("https://repos.ecosyste.ms/api/v1/hosts/#{project_host}/owners/#{project_owner}/repositories?per_page=100&page=#{page}")
        break unless resp.status == 200

        data = JSON.parse(resp.body)
        break if data.empty? # Stop if there are no more repositories

        urls = data.map{|p| p['html_url'] }.uniq.reject(&:blank?)
        urls.each do |url|
          puts url
          project = projects.find_or_create_by(url: url)
          project.sync_async unless project.last_synced_at.present?
          collective_project = collective_projects.find_or_create_by(project_id: project.id)
        end

        page += 1
      end
    else
      project = Project.find_or_create_by(url: project_url)
      project.sync_async if project.last_synced_at.nil?
      collective_project = collective_projects.find_or_create_by(project_id: project.id)
    end
  rescue
    puts "Error loading projects for #{slug}"
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
    first_page = fetch_transactions_from_graphql # TODO handle errors
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
          transaction_type: node['type'],
          transaction_kind: node['kind'],
          transaction_expense_type: node['expense'] ? node['expense']['type'] : nil,
          currency: node['amount']['currency'],
          account: node['type'] == 'DEBIT' ? node['toAccount']['slug'] : node['fromAccount']['slug'],
          created_at: node['createdAt'],
          description: node['description']
        }
      end
      Transaction.upsert_all(transactions, unique_by: :uuid)
      offset += 1000
    end
    update(balance: current_balance)
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
            kind
            expense {
              type
            }
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

  def current_balance
    transactions.sum(:net_amount)
  end
end
