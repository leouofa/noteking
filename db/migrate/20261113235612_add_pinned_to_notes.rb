class AddPinnedToNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :notes, :pinned, :boolean, default: false, null: false
    add_column :notes, :pinned_position, :integer
    add_index :notes, [ :pinned, :pinned_position ]
  end
end
