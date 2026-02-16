class ECTAtSchoolPeriod < ApplicationRecord
  include Interval
  include DeclarativeUpdates

  # Associations
  belongs_to :school, inverse_of: :ect_at_school_periods
  belongs_to :teacher, inverse_of: :ect_at_school_periods
  belongs_to :school_reported_appropriate_body, class_name: "AppropriateBodyPeriod"

  has_many :mentorship_periods, inverse_of: :mentee, dependent: :destroy
  has_many :mentors, through: :mentorship_periods, source: :mentor
  has_many :training_periods, inverse_of: :ect_at_school_period, dependent: :destroy
  has_many :mentor_at_school_periods, through: :teacher
  has_many :events
  has_one :current_or_next_training_period, -> { current_or_future.earliest_first }, class_name: "TrainingPeriod"
  has_one :earliest_training_period, -> { earliest_first }, class_name: "TrainingPeriod"
  has_one :latest_training_period, -> { latest_first }, class_name: "TrainingPeriod"
  has_one :current_or_next_mentorship_period, -> { current_or_future.earliest_first }, class_name: "MentorshipPeriod"
  has_one :latest_mentorship_period, -> { latest_first }, class_name: "MentorshipPeriod"

  touch -> { teacher }, on_event: %i[create destroy update], when_changing: %i[email], timestamp_attribute: :api_updated_at

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
  scope :with_expressions_of_interest_for_lead_provider_and_contract_period, ->(year, lead_provider_id) {
    with_expressions_of_interest_for_contract_period(year)
    .where(expression_of_interest: { lead_provider_id: })
  }
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

  def reported_leaving_by?(school)
    reported_leaving_by_school_id.present? && reported_leaving_by_school_id == school&.id
  end

  def leaving_reported_for_school?(school)
    leaving_today_or_in_future? && reported_leaving_by?(school)
  end

  def school_reported_appropriate_body_name = school_reported_appropriate_body&.name

  def school_reported_appropriate_body_type = school_reported_appropriate_body&.body_type

  def siblings
    return ECTAtSchoolPeriod.none unless teacher

    teacher.ect_at_school_periods.excluding(self)
  end

  def latest_training_status
    latest_training_period&.training_status
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

  delegate :trn, to: :teacher
  delegate :provider_led_training_programme?, to: :current_or_next_training_period, allow_nil: true
  delegate :school_led_training_programme?, to: :current_or_next_training_period, allow_nil: true

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
