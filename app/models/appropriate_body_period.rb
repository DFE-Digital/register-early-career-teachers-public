#
# NB: The purpose of this record is changing. "name" will eventually be stored in different tables.
#
class AppropriateBodyPeriod < ApplicationRecord
  # Enums
  enum :body_type, {
    local_authority: "local_authority",
    national: "national",
    teaching_school_hub: "teaching_school_hub"
  }, validate: {
    message: "Must be local authority, national or teaching school hub"
  }

  # include Interval
  belongs_to :appropriate_body, optional: true

  # Associations
  belongs_to :dfe_sign_in_organisation, primary_key: :uuid, inverse_of: :appropriate_body_period

  # The "Teaching School" or the one "TSH LS with responsibility"
  belongs_to :provisioning_school,
             optional: true,
             class_name: "School",
             foreign_key: :school_id

  belongs_to :teaching_school_hub, optional: true
  belongs_to :national_body, optional: true
  belongs_to :local_authority, optional: true

  # AB -> School & Region
  has_many :teaching_school_hub_lead_schools,
           class_name: "TeachingSchoolHub::LeadSchool",
           foreign_key: :appropriate_body_id,
           inverse_of: :appropriate_body,
           dependent: :destroy

  # region.code : NW3, NW4, NW5
  has_many :regions, through: :teaching_school_hub_lead_schools
  # school.urn :  140_959, 138_220, 141_565
  has_many :lead_schools, -> { distinct }, through: :teaching_school_hub_lead_schools, source: :school

  has_many :pending_induction_submissions
  has_many :induction_periods, inverse_of: :appropriate_body_period
  has_many :events
  has_many :oauth_authorizations, class_name: "API::OAuth::Authorization", dependent: :destroy
  has_many :unclaimed_ect_at_school_periods,
           -> { unclaimed_by_school_reported_appropriate_body },
           class_name: "ECTAtSchoolPeriod",
           foreign_key: :school_reported_appropriate_body_id
  has_many :claimed_ect_at_school_periods,
           -> { claimed_by_school_reported_appropriate_body },
           class_name: "ECTAtSchoolPeriod",
           foreign_key: :school_reported_appropriate_body_id

  # Scopes
  scope :active, -> { where.not(dfe_sign_in_organisation_id: nil) }
  scope :inactive, -> { where(dfe_sign_in_organisation_id: nil) }

  # Validations
  validates :name, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # Predicates
  def active? = dfe_sign_in_organisation_id.present?

  # TODO: remove override once populated
  def provisioning_school
    dfe_sign_in_organisation&.school || super
  end

  alias_method :lead_school, :provisioning_school
end
