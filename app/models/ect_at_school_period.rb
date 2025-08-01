class ECTAtSchoolPeriod < ApplicationRecord
  include Interval
  include DeclarativeTouch

  # Enums
  enum :training_programme,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider-led or school-led" },
       suffix: :training_programme

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :school_reported_appropriate_body, class_name: 'AppropriateBody'

  has_many :mentorship_periods, inverse_of: :mentee
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period
  has_many :mentor_at_school_periods, through: :teacher
  has_many :events

  touch -> { school }, on_event: %i[create destroy], timestamp_attribute: :api_updated_at

  # Validations
  validate :appropriate_body_for_independent_school,
           if: -> { school&.independent? },
           on: :register_ect

  validate :appropriate_body_for_state_funded_school,
           if: -> { school&.state_funded? },
           on: :register_ect

  validates :email,
            notify_email: true,
            allow_nil: true

  validates :school_id,
            presence: true

  validates :started_on,
            presence: true

  validates :teacher_id,
            presence: true

  validate :teacher_distinct_period

  # Scopes
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

  def provider_led?
    training_programme == 'provider_led'
  end

  def school_led?
    training_programme == 'school_led'
  end

  def school_reported_appropriate_body_name = school_reported_appropriate_body&.name

  def school_reported_appropriate_body_type = school_reported_appropriate_body&.body_type

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

  delegate :trn, to: :teacher

private

  def appropriate_body_for_independent_school
    return if school_reported_appropriate_body&.national? || school_reported_appropriate_body&.teaching_school_hub?

    errors.add(:school_reported_appropriate_body_id, 'Must be national or teaching school hub')
  end

  def appropriate_body_for_state_funded_school
    return if school_reported_appropriate_body&.teaching_school_hub?

    errors.add(:school_reported_appropriate_body_id, 'Must be teaching school hub')
  end

  def teacher_distinct_period
    overlap_validation(name: 'Teacher ECT')
  end
end
