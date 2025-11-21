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
      return teacher.most_recent_schedule if teacher.most_recent_provider_led_period

      find_schedule
    end

  private

    def find_schedule
      Schedule.find_by(contract_period_year:, identifier:)
    end

    def provider_led?
      training_programme == "provider_led"
    end

    def teacher
      period.teacher
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
      if schedule_month == "april"
        latest_start_date.year - 1
      else
        latest_start_date.year
      end
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
