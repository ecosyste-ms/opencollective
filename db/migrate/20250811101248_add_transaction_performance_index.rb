class AddTransactionPerformanceIndex < ActiveRecord::Migration[8.0]
  def change
    # Composite index for the most common transaction query pattern:
    # WHERE collective_id IN (...) AND transaction_type = ? AND created_at BETWEEN ? AND ?
    # This covers the exact slow queries identified in production
    add_index :transactions, [:collective_id, :transaction_type, :created_at]
  end
end
