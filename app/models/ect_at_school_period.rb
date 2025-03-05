class ECTAtSchoolPeriod < ApplicationRecord
  include Interval

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
  validates :email, notify_email: true, allow_nil: true
  validates :started_on, presence: true
  validates :school_id, presence: true
  validates :teacher_id, presence: true

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

private

  def teacher_distinct_period
    overlap_validation(name: 'Teacher ECT')
  end
end
