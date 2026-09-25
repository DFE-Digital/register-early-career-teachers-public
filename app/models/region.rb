class Region < ApplicationRecord
  has_many :teaching_school_hub_lead_schools,
           class_name: "TeachingSchoolHub::LeadSchool",
           dependent: :destroy

  has_one :active_teaching_school_hub_lead_school,
          -> { active },
          class_name: "TeachingSchoolHub::LeadSchool",
          dependent: nil,
          inverse_of: :region

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
