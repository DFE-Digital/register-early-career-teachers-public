class TrainingPeriod < ApplicationRecord
  include Interval

  # Associations
  belongs_to :ect_at_school_period, class_name: "ECTAtSchoolPeriod", inverse_of: :training_periods
  belongs_to :mentor_at_school_period, inverse_of: :training_periods
  belongs_to :provider_partnership
  belongs_to :expression_of_interest, optional: true, class_name: "LeadProviderActivePeriod", inverse_of: :expressions_of_interest
  belongs_to :confirmed_school_partnership, optional: true, class_name: "SchoolPartnership"

  has_many :declarations, inverse_of: :training_period
  has_many :events

  has_one :lead_provider, through: :provider_partnership
  has_one :delivery_partner, through: :provider_partnership

  # Validations
  validates :started_on,
            presence: true

  validates :provider_partnership_id,
            presence: true

  validate :one_id_of_trainee_present
  validate :one_partnership_present
  validate :trainee_distinct_period
  validate :enveloped_by_trainee_at_school_period

  # Scopes
  scope :for_ect, ->(ect_at_school_period_id) { where(ect_at_school_period_id:) }
  scope :for_mentor, ->(mentor_at_school_period_id) { where(mentor_at_school_period_id:) }
  scope :for_provider_partnership, ->(provider_partnership_id) { where(provider_partnership_id:) }

  # Instance methods
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

private

  def one_id_of_trainee_present
    ids = [ect_at_school_period_id, mentor_at_school_period_id]
    errors.add(:base, "Id of trainee missing") if ids.none?
    errors.add(:base, "Only one id of trainee required. Two given") if ids.all?
  end

  def one_partnership_present
    partnerships = [expression_of_interest, confirmed_school_partnership]
    errors.add(:base, "Only confirmed partnership or expression of interest is permitted, not both") if partnerships.all?
  end

  def trainee_distinct_period
    overlap_validation(name: 'Trainee')
  end

  def enveloped_by_trainee_at_school_period
    return if (trainee_started_on_at_school..trainee_finished_on_at_school).cover?(started_on..finished_on)

    errors.add(:base, "Date range is not contained by the period the trainee is at the school")
  end

  def trainee_started_on_at_school
    ect_at_school_period&.started_on || mentor_at_school_period&.started_on
  end

  def trainee_finished_on_at_school
    ect_at_school_period&.finished_on || mentor_at_school_period&.finished_on
  end
end
