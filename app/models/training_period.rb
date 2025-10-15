class TrainingPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates

  # Enums
  enum :training_programme,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider_led or school_led" },
       suffix: :training_programme

  enum :withdrawal_reason, {
    left_teaching_profession: "left_teaching_profession",
    moved_school: "moved_school",
    mentor_no_longer_being_mentor: "mentor_no_longer_being_mentor",
    switched_to_school_led: "switched_to_school_led",
    other: "other"
  }, validate: { message: "Must be a valid withdrawal reason", allow_nil: true }, suffix: :withdrawal_reason

  enum :deferral_reason, {
    bereavement: "bereavement",
    long_term_sickness: "long_term_sickness",
    parental_leave: "parental_leave",
    career_break: "career_break",
    other: "other"
  }, validate: { message: "Must be a valid deferral reason", allow_nil: true }, suffix: :deferral_reason

  # Associations
  belongs_to :ect_at_school_period, class_name: "ECTAtSchoolPeriod", inverse_of: :training_periods
  belongs_to :mentor_at_school_period, inverse_of: :training_periods
  belongs_to :school_partnership
  belongs_to :schedule

  has_one :lead_provider_delivery_partnership, through: :school_partnership
  has_one :active_lead_provider, through: :lead_provider_delivery_partnership
  has_one :lead_provider, through: :active_lead_provider
  has_one :delivery_partner, through: :lead_provider_delivery_partnership
  has_one :contract_period, through: :active_lead_provider

  belongs_to :expression_of_interest, class_name: 'ActiveLeadProvider'
  has_one :expression_of_interest_lead_provider, through: :expression_of_interest, source: :lead_provider
  has_one :expression_of_interest_contract_period, through: :expression_of_interest, source: :contract_period

  has_many :declarations, inverse_of: :training_period
  has_many :events

  refresh_metadata -> { school_partnership&.school }, on_event: %i[create destroy update]
  refresh_metadata -> { trainee&.teacher }, on_event: %i[create destroy update], when_changing: %i[started_on finished_on]

  # Validations
  validates :started_on,
            presence: true

  validate :one_id_of_trainee_present
  validate :at_least_expression_of_interest_or_school_partnership_present, if: :provider_led_training_programme?
  validate :expression_of_interest_absent_for_school_led, if: :school_led_training_programme?
  validate :school_partnership_absent_for_school_led, if: :school_led_training_programme?
  validate :trainee_distinct_period
  validate :enveloped_by_trainee_at_school_period
  validate :only_provider_led_mentor_training
  validate :withdrawn_deferred_are_mutually_exclusive
  validates :withdrawn_at, presence: true, if: -> { withdrawal_reason.present? }
  validates :withdrawal_reason, presence: true, if: -> { withdrawn_at.present? }
  validates :deferred_at, presence: true, if: -> { deferral_reason.present? }
  validates :deferral_reason, presence: true, if: -> { deferred_at.present? }
  validate :schedule_contract_period_matches, if: :provider_led_training_programme?
  validate :schedule_absent_for_school_led, if: :school_led_training_programme?

  # Scopes
  scope :for_ect, ->(ect_at_school_period_id) { where(ect_at_school_period_id:) }
  scope :for_mentor, ->(mentor_at_school_period_id) { where(mentor_at_school_period_id:) }
  scope :for_school_partnership, ->(school_partnership_id) { where(school_partnership_id:) }
  scope :at_school, ->(school) {
    left_outer_joins(:ect_at_school_period, :mentor_at_school_period)
      .merge(ECTAtSchoolPeriod.for_school(school).or(MentorAtSchoolPeriod.for_school(school)))
  }

  scope :ect_training_periods_latest_first, ->(teacher:, lead_provider:) {
    includes(:ect_at_school_period, :lead_provider)
    .where(ect_at_school_period: { teacher: }, lead_provider: { id: lead_provider })
    .latest_first
  }
  scope :mentor_training_periods_latest_first, ->(teacher:, lead_provider:) {
    includes(:mentor_at_school_period, :lead_provider)
    .where(mentor_at_school_period: { teacher: }, lead_provider: { id: lead_provider })
    .latest_first
  }

  # Delegations
  delegate :name, to: :delivery_partner, prefix: true, allow_nil: true
  delegate :name, to: :lead_provider, prefix: true, allow_nil: true

  def for_ect?
    ect_at_school_period_id.present?
  end

  def for_mentor?
    mentor_at_school_period_id.present?
  end

  def trainee
    ect_at_school_period || mentor_at_school_period
  end

  def siblings
    return TrainingPeriod.none unless trainee

    trainee.training_periods.excluding(self)
  end

  def only_expression_of_interest?
    school_partnership_id.blank? && expression_of_interest.present?
  end

private

  def one_id_of_trainee_present
    ids = [ect_at_school_period_id, mentor_at_school_period_id]
    errors.add(:base, "Id of trainee missing") if ids.none?
    errors.add(:base, "Only one id of trainee required. Two given") if ids.all?
  end

  def trainee_distinct_period
    overlap_validation(name: 'Trainee')
  end

  def enveloped_by_trainee_at_school_period
    return if finished_on.blank?
    return if (trainee_started_on_at_school..trainee_finished_on_at_school).cover?(started_on..finished_on)

    errors.add(:base, "Date range is not contained by the period the trainee is at the school")
  end

  def trainee_started_on_at_school
    ect_at_school_period&.started_on || mentor_at_school_period&.started_on
  end

  def trainee_finished_on_at_school
    ect_at_school_period&.finished_on || mentor_at_school_period&.finished_on
  end

  def at_least_expression_of_interest_or_school_partnership_present
    return if expression_of_interest.present? || school_partnership.present?

    errors.add(:base, 'Either expression of interest or school partnership required')
  end

  def only_provider_led_mentor_training
    if mentor_at_school_period.present? && school_led_training_programme?
      errors.add(:training_programme, 'Mentor training periods can only be provider-led')
    end
  end

  def expression_of_interest_absent_for_school_led
    return if expression_of_interest.blank?

    errors.add(:expression_of_interest, 'Expression of interest must be absent for school-led training programmes')
  end

  def school_partnership_absent_for_school_led
    return if school_partnership.blank?

    errors.add(:school_partnership, 'School partnership must be absent for school-led training programmes')
  end

  def withdrawn_deferred_are_mutually_exclusive
    return unless withdrawn_at.present? && deferred_at.present?

    errors.add(:base, "A training period cannot be both withdrawn and deferred")
  end

  def schedule_contract_period_matches
    contract_periods_to_check = [contract_period, expression_of_interest_contract_period].compact.uniq

    return if schedule.blank? || contract_periods_to_check.blank?

    unless contract_periods_to_check.all?(schedule.contract_period)
      errors.add(:schedule, "Contract period of schedule must match contract period of EOI and/or school partnership")
    end
  end

  def schedule_absent_for_school_led
    return if schedule.blank?

    errors.add(:schedule, 'Schedule must be absent for school-led training programmes')
  end
end
