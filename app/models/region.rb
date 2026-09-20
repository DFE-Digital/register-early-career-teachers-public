class Region < ApplicationRecord
  has_many :awards,
           class_name: "Region::Award",
           inverse_of: :region,
           dependent: :destroy

  has_one :active_award,
          -> { active },
          class_name: "Region::Award",
          dependent: nil

  # Schools which fall within a district in the region
  has_many :district_schools,
           ->(region) {
             unscope(:where).joins(:gias_school).where(gias_school: {
               administrative_district_name: region.districts
             })
           }, class_name: "School"

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :districts, presence: true
end
