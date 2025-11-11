class MentorAtSchoolPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates

  # Associations
  belongs_to :school, inverse_of: :mentor_at_school_periods
  belongs_to :teacher, inverse_of: :mentor_at_school_periods
  has_many :mentorship_periods, inverse_of: :mentor
  has_many :training_periods, inverse_of: :mentor_at_school_period
  has_many :events
  has_many :currently_assigned_ects,
           -> { ongoing.includes(:teacher) },
           through: :mentorship_periods,
           source: :mentee
  has_one :current_or_next_training_period, -> { current_or_future.earliest_first }, class_name: 'TrainingPeriod'

  touch -> { teacher }, on_event: %i[create destroy update], when_changing: %i[email], timestamp_attribute: :api_updated_at

  refresh_metadata -> { school }, on_event: %i[create destroy update]

  # Validations
  validates :email,
            notify_email: true,
            allow_nil: true

  validates :started_on,
            presence: true

  validates :school_id,
            presence: true

  validates :teacher_id,
            presence: true

  validate :teacher_school_distinct_period

  # Scopes
  scope :for_school, ->(school_id) { where(school_id:) }
  scope :for_teacher, ->(teacher_id) { where(teacher_id:) }
  scope :with_partnerships_for_contract_period, ->(year) {
    joins(training_periods: {
      active_lead_provider: :contract_period
    }).where(contract_periods: { year: })
  }
  scope :with_expressions_of_interest_for_contract_period, ->(year) {
    joins(training_periods: {
      expression_of_interest: :contract_period
    })
    .where(contract_periods: { year: })
  }
  scope :with_expressions_of_interest_for_lead_provider_and_contract_period, ->(year, lead_provider_id) {
    with_expressions_of_interest_for_contract_period(year)
    .where(expression_of_interest: { lead_provider_id: })
  }

  # Instance methods
  def siblings
    return MentorAtSchoolPeriod.none unless teacher

    teacher.mentor_at_school_periods.for_school(school_id).excluding(self)
  end

  delegate :provider_led_training_programme?, to: :current_or_next_training_period, allow_nil: true
  delegate :school_led_training_programme?, to: :current_or_next_training_period, allow_nil: true

private

  def teacher_school_distinct_period
    overlap_validation(name: 'Teacher School Mentor')
  end
end
