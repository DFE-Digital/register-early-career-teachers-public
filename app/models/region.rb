class Region < ApplicationRecord
  belongs_to :appropriate_body

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :districts, presence: true

  alias_method :teaching_school_hub, :appropriate_body
end
