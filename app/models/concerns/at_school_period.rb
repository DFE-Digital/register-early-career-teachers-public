module AtSchoolPeriod
  extend ActiveSupport::Concern

  include Interval
  include DeclarativeUpdates

  included do
    # Associations
    has_many :events

    has_one :current_or_next_training_period, -> { current_or_future.earliest_first }, class_name: "TrainingPeriod"
    has_one :earliest_training_period, -> { earliest_first }, class_name: "TrainingPeriod"
    has_one :latest_training_period, -> { latest_first }, class_name: "TrainingPeriod"

    # Callbacks
    touch -> { teacher }, on_event: %i[create destroy update], when_changing: %i[email], timestamp_attribute: :api_updated_at
    refresh_metadata -> { school }, on_event: %i[create destroy update]
    refresh_metadata -> { teacher }, on_event: %i[create destroy update]

    # Validations
    validates :email,
              notify_email: true,
              allow_nil: true

    validates :school_id,
              presence: true

    validates :started_on,
              presence: true

    validates :teacher_id,
              presence: true

    validate :covering_training_periods, if: -> { persisted? && training_periods.any? }
    validate :covering_mentorship_periods, if: -> { persisted? && mentorship_periods.any? }

    # Scopes
    scope :for_school, ->(school_id) { where(school_id:) }
    scope :for_teacher, ->(teacher_id) { where(teacher_id:) }
    scope :with_school, -> { includes(school: :gias_school) }
    scope :with_teacher, -> { includes(:teacher) }

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
  end

  # Validations
  def covering_training_periods
    current_range = (started_on..finished_on)
    return if training_periods.all? { current_range.cover?(it.range) }

    errors.add(:base, "Date range does not cover all the training periods")
  end

  def covering_mentorship_periods
    current_range = (started_on..finished_on)
    return if mentorship_periods.all? { current_range.cover?(it.range) }

    errors.add(:base, "Date range does not cover all the mentorship periods")
  end

  # Methods
  def leaving_reported_for_school?(school)
    leaving_today_or_in_future? && reported_leaving_by?(school)
  end

  def reported_leaving_by?(school)
    reported_leaving_by_school_id.present? && reported_leaving_by_school_id == school&.id
  end

  delegate :provider_led_training_programme?, to: :current_or_next_training_period, allow_nil: true
  delegate :school_led_training_programme?, to: :current_or_next_training_period, allow_nil: true
end
