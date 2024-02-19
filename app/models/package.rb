class Package < ApplicationRecord
  belongs_to :project

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
    metadata['downloads']
  end

  def dependents
    metadata['dependents']
  end

  def dependent_repositories
    metadata['dependent_repositories']
  end

  def licenses
    metadata['licenses']
  end
end
