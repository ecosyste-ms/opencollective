class Package < ApplicationRecord
  belongs_to :project

  counter_culture :project, column_name: 'packages_count', execute_after_commit: true

  validates :name, presence: true
  validates :ecosystem, presence: true

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
