class MentorshipPeriod < ApplicationRecord
  include Interval

  # Associations
  belongs_to :mentee,
             class_name: "ECTAtSchoolPeriod",
             foreign_key: :ect_at_school_period_id,
             inverse_of: :mentorship_periods

  belongs_to :mentor,
             class_name: "MentorAtSchoolPeriod",
             foreign_key: :mentor_at_school_period_id,
             inverse_of: :mentorship_periods

  has_many :events

  # Validations
  validates :started_on,
            presence: true

  validates :ect_at_school_period_id,
            presence: true

  validates :mentor_at_school_period_id,
            presence: true

  validate :not_self_mentoring
  validate :mentee_distinct_period
  validate :enveloped_by_ect_at_school_period, if: -> { mentee.present? && started_on.present? }
  validate :enveloped_by_mentor_at_school_period, if: -> { mentor.present? && started_on.present? }

  # Scopes
  scope :for_mentee, ->(id) { where(ect_at_school_period_id: id) }
  scope :for_mentor, ->(id) { where(mentor_at_school_period_id: id) }

  # Instance methods
  def siblings
    return MentorshipPeriod.none unless mentee

    mentee.mentorship_periods.excluding(self)
  end

private

  def enveloped_by_ect_at_school_period
    return if (mentee.started_on..mentee.finished_on).cover?(started_on..finished_on)

    errors.add(:base, "Date range is not contained by the ECT at school period")
  end

  def enveloped_by_mentor_at_school_period
    return if (mentor.started_on..mentor.finished_on).cover?(started_on..finished_on)

    errors.add(:base, "Date range is not contained by the mentor at school period")
  end

  def mentee_distinct_period
    overlap_validation(name: 'Mentee')
  end

  def not_self_mentoring
    return unless [mentor&.teacher_id, mentee&.teacher_id].all?
    return if mentor.teacher_id != mentee.teacher_id

    errors.add(:base, "A mentee cannot mentor themself")
  end
end
