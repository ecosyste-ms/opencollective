class AddCriticalIndexes < ActiveRecord::Migration[8.0]
  def change
    # Missing foreign key index - essential for joins
    add_index :advisories, :project_id
    
    # Core business logic filters used throughout the app
    add_index :collectives, :account_type
    add_index :collectives, :host
  end
end
