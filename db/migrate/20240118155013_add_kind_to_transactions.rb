class AddKindToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :transaction_kind, :string
    rename_column :transactions, :kind, :transaction_type
  end
end
