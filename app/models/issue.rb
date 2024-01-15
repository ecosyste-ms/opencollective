class Issue < ApplicationRecord
  belongs_to :project

  scope :label, ->(labels) { where("labels && ARRAY[?]::varchar[]", labels) }
  scope :past_year, -> { where('issues.created_at > ?', 1.year.ago) }
  scope :bot, -> { where('issues.user ILIKE ?', '%[bot]') }
  scope :human, -> { where.not('issues.user ILIKE ?', '%[bot]') }
  scope :with_author_association, -> { where.not(author_association: nil) }
  scope :merged, -> { where.not(merged_at: nil) }
  scope :not_merged, -> { where(merged_at: nil).where.not(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :created_after, ->(date) { where('issues.created_at > ?', date) }
  scope :created_before, ->(date) { where('issues.created_at < ?', date) }
  scope :updated_after, ->(date) { where('updated_at > ?', date) }
  scope :pull_request, -> { where(pull_request: true) }
  scope :issue, -> { where(pull_request: false) }

  def to_param
    number.to_s
  end
end
