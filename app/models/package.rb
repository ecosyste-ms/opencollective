class Package < ApplicationRecord
  belongs_to :project

  counter_culture :project, column_name: 'packages_count', execute_after_commit: true

  validates :name, presence: true
  validates :ecosystem, presence: true

  scope :package_url, ->(package_url) { where(purl: Package.purl_without_version(package_url)) }
  scope :package_urls, ->(package_urls) { where(purl: package_urls.map{|p| Package.purl_without_version(p) }) }

  def self.purl_without_version(purl)
    PackageURL.new(**PackageURL.parse(purl.to_s).to_h.except(:version, :scheme)).to_s
  end

  def registry_name
    metadata["registry"]["name"]
  end

  def keywords
    metadata['keywords']
  end

  def funding
    metadata['metadata']['funding']
  end

  def downloads_period
    metadata['downloads_period']
  end

  def downloads
    metadata['downloads'] || 0
  end

  def dependents
    metadata['dependents'] || 0
  end

  def dependent_repositories
    metadata['dependent_repositories'] || 0
  end

  def licenses
    metadata['licenses']
  end
end
