class Package < ApplicationRecord
  belongs_to :project

  validates :name, presence: true
  validates :ecosystem, presence: true
end
