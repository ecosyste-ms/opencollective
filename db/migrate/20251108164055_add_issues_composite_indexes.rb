class AddIssuesCompositeIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :issues, [:project_id, :pull_request, :created_at]
    add_index :issues, [:project_id, :pull_request, :closed_at]
    add_index :issues, [:project_id, :pull_request, :user]
  end
end
