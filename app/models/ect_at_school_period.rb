class ECTAtSchoolPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :school_reported_appropriate_body, class_name: 'AppropriateBody'

  has_many :mentorship_periods, inverse_of: :mentee
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period
  has_many :mentor_at_school_periods, through: :teacher
  has_many :events
  has_one :current_or_next_training_period, -> { current_or_future.earliest_first }, class_name: 'TrainingPeriod'
  has_one :current_or_next_mentorship_period, -> { current_or_future.earliest_first }, class_name: 'MentorshipPeriod'
  has_one :latest_mentorship_period, -> { latest_first }, class_name: 'MentorshipPeriod'

  refresh_metadata -> { school }, on_event: %i[create destroy update]
  refresh_metadata -> { teacher }, on_event: %i[create destroy]

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

  def school_reported_appropriate_body_name = school_reported_appropriate_body&.name

  def school_reported_appropriate_body_type = school_reported_appropriate_body&.body_type

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

  delegate :trn, to: :teacher
  delegate :provider_led_training_programme?, to: :current_or_next_training_period, allow_nil: true
  delegate :school_led_training_programme?, to: :current_or_next_training_period, allow_nil: true

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
