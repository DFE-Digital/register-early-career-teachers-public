class Region < ApplicationRecord
  belongs_to :teaching_school_hub

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :districts, presence: true
end
