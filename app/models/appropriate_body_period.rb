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

  include Interval

  # Associations
  has_one :legacy_appropriate_body, inverse_of: :appropriate_body_period

  # TODO: remove UUID once linked to DfESignInOrganisation
  belongs_to :dfe_sign_in_organisation, primary_key: :uuid, inverse_of: :appropriate_body_period
  belongs_to :appropriate_body
  has_many :pending_induction_submissions
  has_many :induction_periods, inverse_of: :appropriate_body_period
  has_many :events
  has_many :unclaimed_ect_at_school_periods,
           -> { unclaimed_by_school_reported_appropriate_body },
           class_name: "ECTAtSchoolPeriod",
           foreign_key: :school_reported_appropriate_body_id

  # Scopes
  scope :active, -> { where.not(dfe_sign_in_organisation_id: nil) }
  scope :inactive, -> { where(dfe_sign_in_organisation_id: nil) }
  scope :legacy, -> { where.not(dqt_id: nil) }

  # Validations
  # TODO: remove name once value is available from LegacyAppropriateBody or AppropriateBody
  validates :name, presence: true, uniqueness: true

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # @return [LeadSchoolPeriod::ActiveRecord_AssociationRelation]
  def lead_school_periods
    return unless appropriate_body&.teaching_school_hub?

    appropriate_body.lead_school_periods.containing_period(self)
  end

  # @return [School, nil]
  def lead_school
    return unless appropriate_body&.teaching_school_hub?

    lead_school_periods.first&.school
  end
end
