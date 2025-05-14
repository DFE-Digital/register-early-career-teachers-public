class ECTAtSchoolPeriod < ApplicationRecord
  include Interval

  # Enums
  enum :programme_type,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider-led or school-led" },
       suffix: :programme_type

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :school_reported_appropriate_body, class_name: 'AppropriateBody'
  belongs_to :lead_provider

  has_many :mentorship_periods, inverse_of: :mentee
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period
  has_many :mentor_at_school_periods, through: :teacher
  has_many :events

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

  validates :lead_provider_id,
            absence: {
              message: "Must be nil",
              if: -> { school_led_programme_type? }
            }

  validates :programme_type,
            presence: {
              message: "Must be provider-led",
              if: -> { lead_provider_id }
            }

  validates :school_id,
            presence: true

  validates :started_on,
            presence: true

  validates :teacher_id,
            presence: true

  validate :teacher_distinct_period

  # Scopes
  scope :for_teacher, ->(teacher_id) { where(teacher_id:) }
  scope :latest_for_teacher, ->(teacher) { where(teacher:).order(created_at: :desc) }

  # Instance methods
  def school_reported_appropriate_body_name = school_reported_appropriate_body&.name

  def school_reported_appropriate_body_type = school_reported_appropriate_body&.body_type

  # lead_provider_name
  delegate :name, to: :lead_provider, prefix: true, allow_nil: true

  def current_mentorship = mentorship_periods.ongoing.last

  def current_mentor = current_mentorship&.mentor

  delegate :trn, to: :teacher

  def provider_led?
    programme_type == 'provider_led'
  end

  def school_led?
    programme_type == 'school_led'
  end

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

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
