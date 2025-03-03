class ECTAtSchoolPeriod < ApplicationRecord
  include Interval

  # Enums
  enum :appropriate_body_type,
       { teaching_induction_panel: "teaching_induction_panel",
         teaching_school_hub: "teaching_school_hub" },
       validate: { allow_nil: true },
       suffix: :ab_type

  enum :programme_type,
       { provider_led: "provider_led",
         school_led: "school_led" },
       validate: true,
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
            inclusion: {
              in: ECTAtSchoolPeriod.appropriate_body_types.keys,
              message: "Must be nil or #{ECTAtSchoolPeriod.appropriate_body_types.keys.join(' or ')}",
              allow_nil: true
            },
            presence: {
              message: "Must be 'teaching_school_hub'",
              if: -> { appropriate_body_id }
            }

  validates :email,
            notify_email: true,
            allow_nil: true

  validates :lead_provider_id,
            presence: {
              message: "Must contain the id of a LeadProvider",
              if: -> { provider_led_programme_type? }
            },
            absence: {
              message: "Must be nil",
              unless: -> { provider_led_programme_type? }
            }

  validates :programme_type,
            inclusion: {
              in: School.chosen_programme_types.keys,
              message: "Must be #{School.chosen_programme_types.keys.join(' or ')}"
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
