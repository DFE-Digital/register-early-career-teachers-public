# TODO: rename to AppropriateBodyPeriod
class AppropriateBody < ApplicationRecord
  # TODO: replace body_type with a type check on the AB (TSH or NationalBody)
  # Enums
  enum :body_type, {
    local_authority: "local_authority",
    national: "national",
    teaching_school_hub: "teaching_school_hub"
  }, validate: {
    message: "Must be local authority, national or teaching school hub"
  }

  # TODO: make this a period
  # include Interval

  # Associations
  has_one :legacy_appropriate_body, inverse_of: :appropriate_body_period

  # TODO: remove UUID once linked to DfESignInOrganisation through TSH or NationalBody
  belongs_to :dfe_sign_in_organisation, primary_key: :uuid, inverse_of: :appropriate_body_period
  belongs_to :national_body, optional: true
  belongs_to :teaching_school_hub, optional: true
  belongs_to :lead_school, class_name: "School", optional: true

  has_many :supported_schools, class_name: "School", foreign_key: "last_chosen_appropriate_body_id" # cannot be derived from induction periods which don't link to schools, therefore...
  has_many :pending_induction_submissions
  has_many :induction_periods, inverse_of: :appropriate_body
  has_many :events
  has_many :unclaimed_ect_at_school_periods,
           -> { unclaimed_by_school_reported_appropriate_body },
           class_name: "ECTAtSchoolPeriod",
           foreign_key: :school_reported_appropriate_body_id

  # Scopes
  scope :active, -> { where.not(dfe_sign_in_organisation_id: nil) }
  scope :inactive, -> { where(dfe_sign_in_organisation_id: nil) }
  scope :legacy, -> { local_authority.where(dfe_sign_in_organisation_id: nil) }

  # Validations
  # TODO: remove name once value is available from LegacyAppropriateBody, TSH or NationalBody
  validates :name,
            presence: true,
            uniqueness: true

  validate :only_one_regional_or_national_body
  validate :national_body_limit

  # National Bodies only have one unending AB period (TSHs can have many)
  def national_body_limit
    return if national_body_id.blank?
    return if NationalBody.find(national_body_id).appropriate_body_period.blank?

    errors.add(:base, "A National Body can only have a single Appropriate Body period")
  end

  # Only once an AB has started the migration do we apply additional rules
  def only_one_regional_or_national_body
    return if dfe_sign_in_organisation.blank?

    appropriate_bodies = [teaching_school_hub, national_body].compact

    unless appropriate_bodies.one?
      errors.add(:base, "An Appropriate Body period must be associated with either a Teaching School Hub or a National Body")
    end
  end

  # Normalizations
  normalizes :name, with: -> { it.squish }
end
