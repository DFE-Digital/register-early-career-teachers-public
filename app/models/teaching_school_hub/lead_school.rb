class TeachingSchoolHub::LeadSchool < ApplicationRecord
  belongs_to :appropriate_body,
             class_name: "AppropriateBodyPeriod",
             inverse_of: :teaching_school_hub_lead_schools

  belongs_to :school, inverse_of: :teaching_school_hub_lead_schools
  belongs_to :region, inverse_of: :teaching_school_hub_lead_schools

  scope :active, -> { where(deactivated_at: nil) }

  validates :appropriate_body, :school, :region, presence: true

  validates :region_id,
            uniqueness: {
              conditions: -> { active },
              message: "is already linked to an active lead school"
            }

  validates :region_id,
            uniqueness: {
              scope: :appropriate_body_id,
              message: "is already linked to this appropriate body"
            }

  delegate :urn, :name, to: :school
  delegate :code, :districts, to: :region
end
