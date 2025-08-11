class DropSboms < ActiveRecord::Migration[8.0]
  def change
    drop_table :sboms
  end
end
