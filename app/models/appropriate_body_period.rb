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

  # Associations
  belongs_to :appropriate_body, optional: true
  belongs_to :dfe_sign_in_organisation, primary_key: :uuid, inverse_of: :appropriate_body_period
  belongs_to :provisioning_school,
             optional: true,
             class_name: "School",
             foreign_key: :school_id
  belongs_to :teaching_school_hub, optional: true
  belongs_to :national_body, optional: true
  belongs_to :local_authority, optional: true

  has_many :region_awards,
           class_name: "Region::Award",
           inverse_of: :appropriate_body_period,
           dependent: :destroy
  has_many :regions, through: :region_awards
  has_many :lead_schools, -> { distinct }, through: :region_awards, source: :school
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
end
