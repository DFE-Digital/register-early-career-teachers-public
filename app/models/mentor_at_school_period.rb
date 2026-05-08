class MentorAtSchoolPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates
  include AtSchoolPeriod

  # Associations
  belongs_to :school, inverse_of: :mentor_at_school_periods
  belongs_to :teacher, inverse_of: :mentor_at_school_periods

  has_many :mentorship_periods, inverse_of: :mentor, dependent: :destroy
  has_many :current_or_future_mentorship_periods,
           -> { current_or_future },
           class_name: "MentorshipPeriod"
  has_many :training_periods, inverse_of: :mentor_at_school_period, dependent: :destroy
  has_many :declarations, through: :training_periods
  has_many :lead_provider_metadata_for_mentees,
           class_name: "Metadata::TeacherLeadProvider",
           foreign_key: :ect_assigned_mentor_latest_school_period_id,
           dependent: :nullify,
           inverse_of: :ect_assigned_mentor_latest_school_period
  has_many :current_or_future_ects,
           -> { current_or_future.induction_not_completed.includes(:teacher) },
           through: :current_or_future_mentorship_periods,
           source: :mentee

  touch -> { teacher }, on_event: %i[create destroy update], when_changing: %i[email], timestamp_attribute: :api_unfunded_mentor_updated_at, if: :latest_mentor_at_school_period?

  # Validations
  validate :teacher_school_distinct_period

  # Scopes

  # Instance methods
  def siblings
    return MentorAtSchoolPeriod.none unless teacher

    teacher.mentor_at_school_periods.for_school(school_id).excluding(self)
  end

private

  def teacher_school_distinct_period
    overlap_validation(name: "Teacher School Mentor")
  end

  def latest_mentor_at_school_period?
    teacher.latest_mentor_at_school_period == self
  end
end
