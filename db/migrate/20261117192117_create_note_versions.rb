# frozen_string_literal: true

class CreateNoteVersions < ActiveRecord::Migration[8.1]
  def up
    create_table :note_versions do |t|
      t.references :note, null: false, foreign_key: { on_delete: :cascade }
      t.integer :version_number, null: false
      t.string :title, null: false
      t.text :body, default: "", null: false
      t.datetime :created_at, null: false
    end

    add_index :note_versions, %i[note_id version_number], unique: true
    add_index :note_versions, %i[note_id created_at]

    execute <<~SQL.squish
      INSERT INTO note_versions (note_id, version_number, title, body, created_at)
      SELECT id, 1, title, body, created_at
      FROM notes
    SQL
  end

  def down
    drop_table :note_versions
  end
end
