class ECTAtSchoolPeriod < ApplicationRecord
  include Interval

  # Enums
  enum :appropriate_body_type,
       { teaching_induction_panel: "teaching_induction_panel",
         teaching_school_hub: "teaching_school_hub" },
       validate: { message: "Must be teaching_induction_panel or teaching_school_hub" },
       suffix: :ab_type

  enum :programme_type,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: { message: "Must be provider_led or school_led" },
       suffix: :programme_type

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :appropriate_body
  belongs_to :lead_provider

  has_many :mentorship_periods, inverse_of: :mentee
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period
  has_many :mentor_at_school_periods, through: :teacher
  has_many :events

  # Validations
  validates :appropriate_body_id,
            presence: {
              message: "Must contain the id of an AppropriateBody",
              if: -> { teaching_school_hub_ab_type? }
            },
            absence: {
              message: "Must be nil",
              unless: -> { teaching_school_hub_ab_type? }
            }

  validates :appropriate_body_type,
            presence: {
              message: "Must be teaching_school_hub",
              if: -> { school&.state? }
            }

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
              message: "Must be provider_led",
              if: -> { appropriate_body_id }
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

  # Instance methods
  # appropriate_body_name
  delegate :name, to: :appropriate_body, prefix: true, allow_nil: true

  # lead_provider_name
  delegate :name, to: :lead_provider, prefix: true, allow_nil: true

  def current_mentorship = mentorship_periods.ongoing.last

  def current_mentor = current_mentorship&.mentor

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

  delegate :trn, to: :teacher

  def provider_led?
    programme_type == 'provider_led'
  end

  def school_led?
    programme_type == 'school_led'
  end

private

  def teacher_distinct_period
    overlap_validation(name: 'Teacher ECT')
  end
end
