class AddCommitsCompositeIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :commits, [:project_id, :timestamp]
  end
end
