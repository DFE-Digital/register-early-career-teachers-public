class TrainingPeriod < ApplicationRecord
  include Interval
  include DeclarativeTouch

  # Enums
  enum :training_programme,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider_led or school_led" },
       suffix: :training_programme

  # Associations
  belongs_to :ect_at_school_period, class_name: "ECTAtSchoolPeriod", inverse_of: :training_periods
  belongs_to :mentor_at_school_period, inverse_of: :training_periods
  belongs_to :school_partnership
  belongs_to :expression_of_interest, class_name: 'ActiveLeadProvider'
  has_one :lead_provider_delivery_partnership, through: :school_partnership
  has_one :active_lead_provider, through: :lead_provider_delivery_partnership
  has_one :lead_provider, through: :active_lead_provider
  has_one :delivery_partner, through: :lead_provider_delivery_partnership
  has_one :contract_period, through: :active_lead_provider

  has_many :declarations, inverse_of: :training_period
  has_many :events

  touch -> { trainee.school }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at
  touch -> { trainee.school }, on_event: %i[update], when_changing: %i[expression_of_interest_id], timestamp_attribute: :api_updated_at

  # Validations
  validates :started_on,
            presence: true

  validate :one_id_of_trainee_present
  validate :at_least_expression_of_interest_or_school_partnership_present, if: :provider_led_training_programme?
  validate :trainee_distinct_period
  validate :enveloped_by_trainee_at_school_period

  # Scopes
  scope :for_ect, ->(ect_at_school_period_id) { where(ect_at_school_period_id:) }
  scope :for_mentor, ->(mentor_at_school_period_id) { where(mentor_at_school_period_id:) }
  scope :for_school_partnership, ->(school_partnership_id) { where(school_partnership_id:) }

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
end
