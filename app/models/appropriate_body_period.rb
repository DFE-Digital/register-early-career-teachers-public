class AppropriateBodyPeriod < ApplicationRecord
  # Enums
  enum :body_type, {
    local_authority: "local_authority",
    national: "national",
    teaching_school: "teaching_school",
    teaching_school_hub: "teaching_school_hub"
  }, validate: {
    message: "Must be local authority, national, teaching school hub or teaching school"
  }

  include Interval

  # Associations
  belongs_to :dfe_sign_in_organisation, primary_key: :uuid, inverse_of: :appropriate_body_period
  belongs_to :provisioning_school, optional: true, class_name: "School", foreign_key: :school_id
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

  # Normalizations
  normalizes :name, with: -> { it.squish }

  # Validations
  # TODO: after date population on production add a migration to set NOT NULL on started_on
  validates :started_on, presence: true
  # Teaching School Hub or Teaching School
  validate :no_overlapping_periods_for_same_provisioning_school, if: :provisioning_school
  validate :started_on_before_provisioning_school_opened, if: :provisioning_school
  validate :finished_on_after_provisioning_school_closed, if: :provisioning_school
  # Teaching School Hub only
  validate :started_on_before_teaching_school_hub_body_introduced, if: :teaching_school_hub?
  # Teaching School only
  validates :finished_on, presence: true, if: :teaching_school?
  validate :started_on_before_teaching_school_body_introduced, if: :teaching_school?
  validate :started_on_after_teaching_school_body_retired, if: :teaching_school?
  validate :finished_on_after_teaching_school_body_retired, if: :teaching_school?
  # Local Authority only
  validates :finished_on, presence: true, if: :local_authority?
  validate :started_on_before_local_authority_body_introduced, if: :local_authority?
  validate :started_on_after_local_authority_body_retired, if: :local_authority?
  validate :finished_on_after_local_authority_body_retired, if: :local_authority?

  # Predicates
  def active? = dfe_sign_in_organisation_id.present?

private

  # TODO: return to commented query when started_on is NOT NULL and production is populated
  def siblings
    return self.class.none if school_id.nil?

    # self.class.where(school_id:).excluding(self)
    self.class.where(school_id:).excluding(self).where.not(started_on: nil, finished_on: nil)
  end

  def no_overlapping_periods_for_same_provisioning_school
    return if started_on.nil?

    overlap_validation(name: "appropriate body")
  end

  def started_on_before_local_authority_body_introduced
    return if started_on.blank?

    introduced_on = ::LocalAuthority::APPROPRIATE_BODY[:introduced_on]
    return if started_on >= introduced_on

    errors.add(:started_on, "Local authority appropriate bodies must start on or after #{introduced_on.to_fs(:govuk)}")
  end

  def finished_on_after_local_authority_body_retired
    return if unfinished?

    retired_on = ::LocalAuthority::APPROPRIATE_BODY[:retired_on]
    return if finished_on <= retired_on

    errors.add(:finished_on, "Local authority appropriate bodies must finish on or before #{retired_on.to_fs(:govuk)}")
  end

  def started_on_after_local_authority_body_retired
    return if started_on.blank?

    retired_on = ::LocalAuthority::APPROPRIATE_BODY[:retired_on]
    return if started_on <= retired_on

    errors.add(:started_on, "A local authority appropriate body must start on or before #{retired_on.to_fs(:govuk)}")
  end

  def started_on_before_teaching_school_hub_body_introduced
    return if started_on.blank?

    introduced_on = ::TeachingSchoolHub::APPROPRIATE_BODY[:introduced_on]
    return if started_on >= introduced_on

    errors.add(:started_on, "Teaching school hub appropriate bodies must start on or after #{introduced_on.to_fs(:govuk)}")
  end

  def started_on_before_teaching_school_body_introduced
    return if started_on.blank?

    introduced_on = ::School::APPROPRIATE_BODY[:introduced_on]
    return if started_on >= introduced_on

    errors.add(:started_on, "Teaching school appropriate bodies must start on or after #{introduced_on.to_fs(:govuk)}")
  end

  def finished_on_after_teaching_school_body_retired
    return if unfinished?

    retired_on = ::School::APPROPRIATE_BODY[:retired_on]
    return if finished_on <= retired_on

    errors.add(:finished_on, "Teaching school appropriate bodies must finish on or before #{retired_on.to_fs(:govuk)}")
  end

  def started_on_after_teaching_school_body_retired
    return if started_on.blank?

    retired_on = ::School::APPROPRIATE_BODY[:retired_on]
    return if started_on <= retired_on

    errors.add(:started_on, "Teaching school appropriate bodies must start on or before #{retired_on.to_fs(:govuk)}")
  end

  def started_on_before_provisioning_school_opened
    return if started_on.blank?

    opened_on = provisioning_school.opened_on
    return if opened_on.blank?
    return if started_on >= opened_on

    errors.add(:started_on, "The start date cannot be earlier than the school opened (#{opened_on.to_fs(:govuk)})")
  end

  def finished_on_after_provisioning_school_closed
    return if unfinished?

    closed_on = provisioning_school.closed_on
    return if closed_on.blank?
    return if finished_on <= closed_on

    errors.add(:finished_on, "The end date cannot be later than the school closed (#{closed_on.to_fs(:govuk)})")
  end
end
