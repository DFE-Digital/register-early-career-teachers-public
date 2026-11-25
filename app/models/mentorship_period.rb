class MentorshipPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates
  include LeadProviderEventTrackable

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
  validate :mentor_and_mentee_periods_are_at_same_school, if: -> { mentor.present? && mentee.present? }
  validate :mentee_distinct_period
  validate :enveloped_by_ect_at_school_period, if: -> { mentee.present? && started_on.present? }
  validate :enveloped_by_mentor_at_school_period, if: -> { mentor.present? && started_on.present? }

  # Scopes
  scope :for_mentee, ->(id) { where(ect_at_school_period_id: id) }
  scope :for_mentor, ->(id) { where(mentor_at_school_period_id: id) }
  scope :involving_teacher, ->(teacher_id) {
    for_mentee(ECTAtSchoolPeriod.where(teacher_id:).select(:id))
      .or(for_mentor(MentorAtSchoolPeriod.where(teacher_id:).select(:id)))
  }
  scope :affected_by, ->(event) { where(id: event.mentorship_period_id).or(involving_teacher(event.teacher_id)) }

  refresh_metadata -> { mentee.teacher }, on_event: %i[create destroy update]

  # Instance methods
  def lead_providers
    LeadProvider
      .joins(:training_periods)
      .where(training_periods: { ect_at_school_period_id: })
      .where(framework_agreements: { contract_period_year: ContractPeriod.enabled.select(:year) })
      .where("training_periods.finished_on IS NULL OR training_periods.finished_on > ?", started_on)
      .distinct
  end

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
    overlap_validation(name: "Mentee")
  end

  def not_self_mentoring
    return unless [mentor&.teacher_id, mentee&.teacher_id].all?
    return if mentor.teacher_id != mentee.teacher_id

    errors.add(:base, "A mentee cannot mentor themself")
  end

  def mentor_and_mentee_periods_are_at_same_school
    # A MentorshipPeriod must link a mentor-at-school period and an ECT-at-school period
    # that belong to the same school.
    #
    # This validation is scoped to the at-school periods, not the teachers themselves:
    # a mentor may mentor at different schools in different periods.
    return if mentor.school_id == mentee.school_id

    errors.add(:base, "Mentor and mentee periods must belong to the same school")
  end
end
