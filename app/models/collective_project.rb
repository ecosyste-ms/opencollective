class CollectiveProject < ApplicationRecord
  belongs_to :collective
  belongs_to :project

  counter_culture :collective, column_name: 'projects_count', execute_after_commit: true
end
