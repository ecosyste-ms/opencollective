class Tag < ApplicationRecord
  belongs_to :project

  scope :since, ->(date) { where('tags.published_at > ?', date) }
  scope :until, ->(date) { where('tags.published_at < ?', date) }

  scope :created_after, ->(date) { where('tags.published_at > ?', date) }
  scope :created_before, ->(date) { where('tags.published_at < ?', date) }

  scope :this_period, ->(period) { where('tags.published_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('tags.published_at > ?', (period*2).days.ago).where('tags.published_at < ?', period.days.ago) }
end
