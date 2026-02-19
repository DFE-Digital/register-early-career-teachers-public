module Schedules
  class Find
    attr_accessor :period, :training_programme, :started_on, :period_type_key, :mentee

    def initialize(period:, training_programme:, started_on:, period_type_key:, mentee:)
      @period = period
      @training_programme = training_programme
      @started_on = started_on
      @period_type_key = period_type_key
      @mentee = mentee
    end

    def call
      return unless provider_led?

      schedule_for_target_period
    end

  private

    def schedule_for_target_period
      return most_recent_schedule if most_recent_schedule&.contract_period_year == contract_period_year

      Schedule.find_by(contract_period_year:, identifier: most_recent_schedule&.identifier) || Schedule.find_by(contract_period_year:, identifier:)
    end

    def provider_led?
      training_programme == "provider_led"
    end

    def teacher
      period.teacher
    end

    def training_periods
      return teacher.ect_training_periods if teacher.ect_at_school_periods.exists? && period_type_key == :ect_at_school_period

      teacher.mentor_training_periods if teacher.mentor_at_school_periods.exists?
    end

    def most_recent_provider_led_period
      training_periods&.provider_led_training_programme&.latest_first&.first
    end

    def most_recent_schedule
      @most_recent_schedule ||= most_recent_provider_led_period&.schedule
    end

    def latest_start_date
      [started_on, Time.zone.today].max
    end

    def schedule_month
      month = latest_start_date.month

      case month
      when 6..10
        "september"
      when 11, 12, 1, 2
        "january"
      when 3..5
        "april"
      end
    end

    def contract_period_year
      ContractPeriod.containing_date_end_inclusive(latest_start_date)&.year || raise(ActiveRecord::RecordNotFound, "No contract period for #{latest_start_date}")
    end

    def identifier
      identifier_type = replacement_schedule? ? "replacement" : "standard"

      "ecf-#{identifier_type}-#{schedule_month}"
    end

    def mentorship_periods_for_mentee_with_different_mentor
      MentorAtSchoolPeriod
        .joins(:mentorship_periods)
        .merge(MentorshipPeriod.for_mentee(mentee.id))
        .where.not(id: period.id)
    end

    def previous_mentor_started_training?
      mentorship_periods_for_mentee_with_different_mentor.joins(:declarations).exists?
    end

    def replacement_schedule?
      return false unless period_type_key == :mentor_at_school_period
      return false unless mentee && mentee.provider_led_training_programme?
      return false if teacher.mentor_became_ineligible_for_funding_on.present?

      previous_mentor_started_training?
    end
  end
end
