class Commit < ApplicationRecord
  belongs_to :project

  scope :since, ->(date) { where('timestamp > ?', date) }
  scope :until, ->(date) { where('timestamp < ?', date) }

  scope :author, ->(author) { where(author: author) }
  scope :committer, ->(committer) { where(committer: committer) }
  scope :merges, -> { where(merge: true) }

  scope :created_after, ->(date) { where('commits.timestamp > ?', date) }
  scope :created_before, ->(date) { where('commits.timestamp < ?', date) }

  scope :this_period, ->(period) { where('commits.timestamp > ?', period.days.ago) }
  scope :last_period, ->(period) { where('commits.timestamp > ?', (period*2).days.ago).where('commits.timestamp < ?', period.days.ago) }
end
