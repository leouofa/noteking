# frozen_string_literal: true

class NoteVersion < ApplicationRecord
  belongs_to :note, inverse_of: :versions

  validates :version_number,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :note_id }
  validates :title, presence: true

  scope :ordered, -> { order(version_number: :desc) }
end
