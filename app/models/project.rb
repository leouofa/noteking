class Project < ApplicationRecord
  has_many :notes, -> { order(updated_at: :desc) }, dependent: :nullify

  validates :name, presence: true
end
