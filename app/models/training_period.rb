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

  belongs_to :expression_of_interest, class_name: "ActiveLeadProvider"
  has_one :expression_of_interest_lead_provider, through: :expression_of_interest, source: :lead_provider
  has_one :expression_of_interest_contract_period, through: :expression_of_interest, source: :contract_period

  has_many :declarations, inverse_of: :training_period
  has_many :events

  touch -> { self }, when_changing: %i[started_on finished_on], timestamp_attribute: :api_transfer_updated_at
  touch -> { teacher },
        on_event: %i[create destroy update],
        timestamp_attribute: :api_updated_at,
        when_changing: %i[
          withdrawn_at
          withdrawal_reason
          deferred_at
          deferral_reason
          started_on
          finished_on
          ect_at_school_period_id
          mentor_at_school_period_id
          schedule_id
          school_partnership_id
        ]

  refresh_metadata -> { at_school_period.school }, on_event: %i[create destroy update], when_changing: %i[school_partnership_id expression_of_interest_id]
  refresh_metadata -> { teacher }, on_event: %i[create destroy update], when_changing: %i[started_on finished_on withdrawn_at deferred_at school_partnership_id]

  # Validations
  validates :started_on,
            presence: true

  validate :only_one_at_school_period_present
  validate :at_least_expression_of_interest_or_school_partnership_present, if: :provider_led_training_programme?
  validate :expression_of_interest_absent_for_school_led, if: :school_led_training_programme?
  validate :school_partnership_absent_for_school_led, if: :school_led_training_programme?
  validate :school_consistency
  validate :trainee_distinct_period
  validate :enveloped_by_trainee_at_school_period
  validate :only_provider_led_mentor_training
  validates :withdrawn_at, presence: true, if: -> { withdrawal_reason.present? }
  validates :withdrawal_reason, presence: true, if: -> { withdrawn_at.present? }
  validates :deferred_at, presence: true, if: -> { deferral_reason.present? }
  validates :deferral_reason, presence: true, if: -> { deferred_at.present? }
  validates :schedule, presence: { message: "Schedule is required for provider-led training periods" }, if: :provider_led_training_programme?
  validate :contract_period_consistent_across_associations, if: :provider_led_training_programme?
  validate :schedule_absent_for_school_led, if: :school_led_training_programme?
  validate :schedule_applicable_for_trainee
  with_options if: -> { started_on&.future? } do
    validates :withdrawn_at, absence: true
    validates :withdrawal_reason, absence: true
    validates :deferred_at, absence: true
    validates :deferral_reason, absence: true
  end

  # Scopes
  scope :for_ect, ->(ect_at_school_period_id) { where(ect_at_school_period_id:) }
  scope :for_mentor, ->(mentor_at_school_period_id) { where(mentor_at_school_period_id:) }
  scope :for_school_partnership, ->(school_partnership_id) { where(school_partnership_id:) }
  scope :for_mentor_trn, ->(trn) { joins(mentor_at_school_period: :teacher).where(teachers: { trn: }) }
  scope :confirmed, -> { where.not(school_partnership_id: nil) }
  scope :at_school, ->(school) {
    left_outer_joins(:ect_at_school_period, :mentor_at_school_period)
      .where(
        ECTAtSchoolPeriod.arel_table[:school_id].eq(school.id)
        .or(MentorAtSchoolPeriod.arel_table[:school_id].eq(school.id))
      )
  }
  scope :including_school_partnership, -> {
    includes(:school_partnership)
  }

  # Delegations
  delegate :name, to: :delivery_partner, prefix: true, allow_nil: true
  delegate :name, to: :lead_provider, prefix: true, allow_nil: true
  delegate :teacher, :teacher_id, :school, :school_id, :mentorship_periods, :email, to: :at_school_period, allow_nil: true
  delegate :started_on, :finished_on, to: :at_school_period, prefix: true, allow_nil: true

  def for_ect?
    ect_at_school_period_id.present?
  end

  def for_mentor?
    mentor_at_school_period_id.present?
  end

  def partnership_change_requires_replacement?
    started_on.present? && started_on < Date.current && finished_on.blank?
  end

  def partnership_change_eligible?
    provider_led_training_programme? && finished_on.blank?
  end

  def at_school_period
    ect_at_school_period || mentor_at_school_period
  end

  def siblings
    return TrainingPeriod.none unless at_school_period

    at_school_period.training_periods.excluding(self)
  end

  def only_expression_of_interest?
    school_partnership_id.blank? && expression_of_interest.present?
  end

  def self.latest_for_mentor_trn(trn)
    for_mentor_trn(trn)
      .latest_first
      .first
  end

  def self.latest_confirmed_for_mentor_trn(trn)
    for_mentor_trn(trn)
      .confirmed
      .including_school_partnership
      .latest_first
      .first
  end

  def teacher_completed_training?
    if for_ect?
      teacher.finished_induction_period&.complete?
    else
      teacher.mentor_became_ineligible_for_funding_on.present?
    end
  end

  def eligible_for_funding?
    if for_ect?
      teacher.ect_first_became_eligible_for_training_at.present?
    else
      teacher.mentor_first_became_eligible_for_training_at.present?
    end
  end

private

  def only_one_at_school_period_present
    ids = [ect_at_school_period_id, mentor_at_school_period_id]

    errors.add(:base, "Either an ECT at school period or mentor at school period is required") if ids.none?
    errors.add(:base, "Can belong to either an ECT at school period or a mentor at school period, not both") if ids.all?
  end

  def trainee_distinct_period
    overlap_validation(name: "Trainee")
  end

  def enveloped_by_trainee_at_school_period
    return if finished_on.blank?
    return if (at_school_period_started_on..at_school_period_finished_on).cover?(started_on..finished_on)

    errors.add(:base, "Date range is not contained by the period the trainee is at the school")
  end

  def at_least_expression_of_interest_or_school_partnership_present
    return if expression_of_interest.present? || school_partnership.present?

    errors.add(:base, "Either expression of interest or school partnership required")
  end

  def only_provider_led_mentor_training
    if mentor_at_school_period.present? && school_led_training_programme?
      errors.add(:training_programme, "Mentor training periods can only be provider-led")
    end
  end

  def expression_of_interest_absent_for_school_led
    return if expression_of_interest.blank?

    errors.add(:expression_of_interest, "Expression of interest must be absent for school-led training programmes")
  end

  def school_partnership_absent_for_school_led
    return if school_partnership.blank?

    errors.add(:school_partnership, "School partnership must be absent for school-led training programmes")
  end

  def contract_period_consistent_across_associations
    associated_contract_periods = [contract_period, expression_of_interest_contract_period, schedule&.contract_period]
    associated_contract_periods += declarations.map { |dec| [dec.payment_statement&.contract_period, dec.clawback_statement&.contract_period] }.flatten

    return unless associated_contract_periods.compact.uniq.many?

    errors.add(:schedule, "Contract period mismatch: schedule, EOI, school partnership, and declarations must have the same contract period.")
  end

  def schedule_absent_for_school_led
    return if schedule.blank?

    errors.add(:schedule, "Schedule must be absent for school-led training programmes")
  end

  def schedule_applicable_for_trainee
    return if schedule.blank?
    return unless for_ect?

    errors.add(:schedule, "Only mentors can be assigned to replacement schedules") if schedule.replacement_schedule?
  end

  def school_consistency
    return if at_school_period.blank?
    return if school_partnership.blank?
    return if school_partnership.school == school

    extra = { teacher_id:, school_partnership_id: school_partnership.id, trainee_school_id: school_id }
    Sentry.capture_message("[Data integrity] Attempt to assign school partnership to a different school from the school period", level: :error, extra:)
    errors.add(:school_partnership, "School partnership's school must match the trainee's school")
  end
end
