class MentorAtSchoolPeriod < ApplicationRecord
  include Interval

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

  after_commit :touch_school_api_updated_at_if_first_mentor_and_no_ects, on: :create
  after_commit :touch_school_api_updated_at_if_first_mentor_and_only_school_led_ects, on: :create
  after_commit :touch_school_api_updated_at_if_no_mentors_or_ects, on: :destroy
  after_commit :touch_school_api_updated_at_if_last_mentor_and_only_school_led_ects, on: :destroy

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

private

  def teacher_school_distinct_period
    overlap_validation(name: 'Teacher School Mentor')
  end

  def touch_school_api_updated_at_if_first_mentor_and_no_ects
    return if school.mentor_at_school_periods.count > 1
    return if school.ect_at_school_periods.any?

    school.touch(:api_updated_at)
  end

  def touch_school_api_updated_at_if_first_mentor_and_only_school_led_ects
    return if school.mentor_at_school_periods.count > 1
    return if school.ect_at_school_periods.provider_led.any?

    school.touch(:api_updated_at)
  end

  def touch_school_api_updated_at_if_no_mentors_or_ects
    return if school.mentor_at_school_periods.reload.any?
    return if school.ect_at_school_periods.any?

    school.touch(:api_updated_at)
  end

  def touch_school_api_updated_at_if_last_mentor_and_only_school_led_ects
    return if school.mentor_at_school_periods.reload.any?
    return if school.ect_at_school_periods.provider_led.any?

    school.touch(:api_updated_at)
  end
end
