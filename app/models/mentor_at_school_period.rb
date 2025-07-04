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
  scope :for_contract_period, ->(year) {
    joins(training_periods: {
      school_partnership: {
        lead_provider_delivery_partnership: {
          active_lead_provider: :contract_period
        }
      }
    }).where(contract_periods: { year: })
  }
  scope :with_expressions_of_interest_for_lead_provider_and_contract_period, ->(lead_provider_id, year) {
    joins(training_periods: {
      expression_of_interest: %i[contract_period lead_provider]
    })
    .where(lead_provider: { id: lead_provider_id })
    .where(contract_periods: { year: })
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
end
