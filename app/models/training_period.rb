class TrainingPeriod < ApplicationRecord
  include Interval

  # Associations
  belongs_to :ect_at_school_period, class_name: "ECTAtSchoolPeriod", inverse_of: :training_periods
  belongs_to :mentor_at_school_period, inverse_of: :training_periods
  belongs_to :school_partnership, optional: true
  belongs_to :expression_of_interest, class_name: "LeadProviderActivePeriod", inverse_of: :expressions_of_interest

  has_many :declarations, inverse_of: :training_period
  has_many :events

  has_one :lead_provider, through: :school_partnership
  has_one :delivery_partner, through: :school_partnership

  # Validations
  validates :started_on, presence: true

  validate :at_least_one_partnership
  validate :one_id_of_trainee_present
  validate :trainee_distinct_period
  validate :enveloped_by_trainee_at_school_period
  validate :school_partnership_school_is_consistent

  # Scopes
  scope :for_ect, ->(ect_at_school_period_id) { where(ect_at_school_period_id:) }
  scope :for_mentor, ->(mentor_at_school_period_id) { where(mentor_at_school_period_id:) }
  scope :for_school_partnership, ->(school_partnership_id) { where(school_partnership_id:) }
  scope :for_school, ->(school) do
    left_outer_joins(:ect_at_school_period, :mentor_at_school_period)
    .where("ect_at_school_periods.school_id = :school_id OR mentor_at_school_periods.school_id = :school_id", school_id: school.id)
  end

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

  def school_partnership_school_is_consistent
    school_ids = [school_partnership&.school_id, ect_at_school_period&.school_id, mentor_at_school_period&.school_id].compact
    return if school_ids.uniq.one?

    errors.add(:base, "School partnership is not consistent with the trainee's school")
  end

  def at_least_one_partnership
    ids = [expression_of_interest_id, school_partnership_id]
    errors.add(:base, "An expression of interest or school partnership is required") if ids.none?
  end

  def one_id_of_trainee_present
    ids = [ect_at_school_period_id, mentor_at_school_period_id]
    errors.add(:base, "Id of trainee missing") if ids.none?
    errors.add(:base, "Only one id of trainee required. Two given") if ids.all?
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
