class Collective < ApplicationRecord
  validates :slug, presence: true

  has_many :collective_projects, dependent: :destroy
  has_many :projects, through: :collective_projects

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

    response = Faraday.post('https://api.opencollective.com/graphql/v2', { query: query }.to_json, { 'Content-Type' => 'application/json' })
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
end
