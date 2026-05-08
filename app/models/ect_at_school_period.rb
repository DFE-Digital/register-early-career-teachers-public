class ECTAtSchoolPeriod < ApplicationRecord
  RECT_GO_LIVE_DATE = Date.new(2026, 4, 28).freeze

  include Interval
  include DeclarativeUpdates
  include AtSchoolPeriod

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :school_reported_appropriate_body, class_name: "AppropriateBodyPeriod"

  has_many :mentorship_periods, inverse_of: :mentee, dependent: :destroy
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period, dependent: :destroy
  has_many :mentor_at_school_periods, through: :teacher

  has_one :current_or_next_mentorship_period, -> { current_or_future.earliest_first }, class_name: "MentorshipPeriod"
  has_one :latest_mentorship_period, -> { latest_first }, class_name: "MentorshipPeriod"

  # Validations
  validate :appropriate_body_for_independent_school,
           if: -> { school&.independent? },
           on: :register_ect

  validate :appropriate_body_for_state_funded_school,
           if: -> { school&.state_funded? },
           on: :register_ect

  validate :teacher_distinct_period

  # Scopes
  scope :unclaimed_by_school_reported_appropriate_body, -> {
    current_or_future
      .where.not(school_reported_appropriate_body_id: nil)
      .joins(:teacher)
      .joins(<<~SQL)
        LEFT OUTER JOIN induction_periods
          ON induction_periods.teacher_id = ect_at_school_periods.teacher_id
          AND induction_periods.finished_on IS NULL
          AND induction_periods.appropriate_body_period_id = ect_at_school_periods.school_reported_appropriate_body_id
      SQL
      .where(induction_periods: { id: nil })
  }
  scope :claimed_by_school_reported_appropriate_body, -> {
    where.not(school_reported_appropriate_body_id: nil)
      .joins(:teacher)
      .joins(<<~SQL)
        INNER JOIN induction_periods
          ON induction_periods.teacher_id = ect_at_school_periods.teacher_id
          AND induction_periods.finished_on IS NULL
          AND induction_periods.appropriate_body_period_id = ect_at_school_periods.school_reported_appropriate_body_id
      SQL
  }
  scope :without_ongoing_period_at_same_appropriate_body, -> {
    where(<<~SQL)
      NOT EXISTS (
        SELECT 1 FROM ect_at_school_periods AS ongoing_periods
        WHERE ongoing_periods.teacher_id = ect_at_school_periods.teacher_id
        AND ongoing_periods.id != ect_at_school_periods.id
        AND ongoing_periods.finished_on IS NULL
        AND ongoing_periods.school_reported_appropriate_body_id = ect_at_school_periods.school_reported_appropriate_body_id
      )
    SQL
  }
  scope :marked_as_leaving_without_ongoing_period_at_same_appropriate_body, -> { finished.without_ongoing_period_at_same_appropriate_body }
  scope :induction_not_completed, -> {
    joins("LEFT JOIN teachers AS induction_teachers ON induction_teachers.id = ect_at_school_periods.teacher_id")
    .where(
      "induction_teachers.trs_induction_status NOT IN (?)
       OR induction_teachers.trs_induction_status IS NULL",
      %w[Passed Failed]
    )
  }
  scope :claimed_by_different_appropriate_body, -> {
    current_or_future
      .joins(:teacher)
      .joins(<<~SQL)
        INNER JOIN induction_periods AS active_induction_periods
          ON active_induction_periods.teacher_id = ect_at_school_periods.teacher_id
          AND active_induction_periods.finished_on IS NULL
          AND active_induction_periods.appropriate_body_period_id != ect_at_school_periods.school_reported_appropriate_body_id
      SQL
  }
  scope :without_qts_award, -> { joins(:teacher).merge(Teacher.without_qts_award) }
  scope :claimable, -> {
    where.not(id: without_qts_award)
      .where.not(id: claimed_by_different_appropriate_body)
  }
  scope :with_teacher_current_induction_period_appropriate_body, -> {
    includes(teacher: { current_or_next_induction_period: :appropriate_body_period })
  }

  def school_reported_appropriate_body_name = school_reported_appropriate_body&.name

  def school_reported_appropriate_body_type = school_reported_appropriate_body&.body_type

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

  def latest_training_status
    latest_training_period&.status
  end

  def latest_lead_provider_name
    training_period = latest_training_period
    return if training_period.blank?

    if training_period.only_expression_of_interest?
      training_period.expression_of_interest_lead_provider&.name
    else
      training_period.lead_provider_name
    end
  end

  def alternative_mentors_available?
    current_mentor = current_or_next_mentorship_period&.mentor

    mentors = Schools::EligibleMentors.new(school).for_ect(self)

    mentors.excluding(current_mentor).exists?
  end

  def migrated_data_accurate?
    teacher.not_migrated_migration_mode? || created_at.after?(RECT_GO_LIVE_DATE.beginning_of_day)
  end

  delegate :trn, :trs_initial_teacher_training_provider_name, to: :teacher
  delegate :name, to: :school, prefix: true

private

  def appropriate_body_for_independent_school
    return if school_reported_appropriate_body&.national? || school_reported_appropriate_body&.teaching_school_hub?

    errors.add(:school_reported_appropriate_body_id, "Must be national or teaching school hub")
  end

  def appropriate_body_for_state_funded_school
    return if school_reported_appropriate_body&.teaching_school_hub?

    errors.add(:school_reported_appropriate_body_id, "Must be teaching school hub")
  end

  def teacher_distinct_period
    overlap_validation(name: "Teacher ECT")
  end
end
