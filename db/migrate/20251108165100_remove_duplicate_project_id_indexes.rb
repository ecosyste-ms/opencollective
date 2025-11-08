class RemoveDuplicateProjectIdIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :commits, :project_id, if_exists: true
    remove_index :issues, :project_id, if_exists: true
  end
end
