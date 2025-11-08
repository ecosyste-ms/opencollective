class RemoveDuplicateTransactionIndex < ActiveRecord::Migration[8.0]
  def change
    # This index is redundant - covered by idx_on_collective_id_transaction_type_created_at
    # Removing it speeds up writes (INSERTs/UPDATEs) to transactions table
    remove_index :transactions, :collective_id, if_exists: true
  end
end
