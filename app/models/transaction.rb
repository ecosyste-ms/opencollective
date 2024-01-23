class Transaction < ApplicationRecord
  belongs_to :collective
  validates :uuid, uniqueness: true

  counter_culture :collective, execute_after_commit: true

  scope :donations, -> { where(transaction_type: 'CREDIT') }
  scope :expenses, -> { where(transaction_type: 'DEBIT') }
  scope :host_fees, -> { where(description: "Host Fee")}
  scope :not_host_fees, -> { where.not(description: "Host Fee")}
  scope :created_after, ->(date) { where('created_at > ?', date) }
  scope :created_before, ->(date) { where('created_at < ?', date) }

  scope :this_period, ->(period) { where('transactions.created_at > ?', period.days.ago) }
  scope :last_period, ->(period) { where('transactions.created_at > ?', (period*2).days.ago).where('transactions.created_at < ?', period.days.ago) }
end
