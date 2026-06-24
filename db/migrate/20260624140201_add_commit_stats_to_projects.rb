class AddCommitStatsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :commit_stats, :json
  end
end
