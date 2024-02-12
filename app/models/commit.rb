class Commit < ApplicationRecord
  belongs_to :project

  scope :since, ->(date) { where('timestamp > ?', date) }
  scope :until, ->(date) { where('timestamp < ?', date) }
end
