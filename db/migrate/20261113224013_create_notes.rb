class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :project, null: true, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :body, default: "", null: false

      t.timestamps
    end

    add_index :notes, :updated_at
  end
end
