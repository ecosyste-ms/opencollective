class AddTransactionUpdatedAtIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :transactions, [:collective_id, :updated_at]
  end
end
