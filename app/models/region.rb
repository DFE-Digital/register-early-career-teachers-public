class Region < ApplicationRecord
  has_many :awards,
           class_name: "Region::Award",
           inverse_of: :region,
           dependent: :destroy

  has_one :active_award,
          -> { active },
          class_name: "Region::Award",
          dependent: nil

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :districts, presence: true

  def district_schools
    School
      .joins(:gias_school)
      .where(
        gias_school: {
          administrative_district_name: districts,
          status: %i[open proposed_to_close]
        }
      )
  end
end
