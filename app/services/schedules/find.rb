module Schedules
  class Find
    attr_accessor :period, :training_programme, :started_on

    def initialize(period:, training_programme:, started_on:)
      @period = period
      @training_programme = training_programme
      @started_on = started_on
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

    # TODO: in due course, we will assign non-standard identifiers
    def identifier
      "ecf-standard-#{schedule_month}"
    end
  end
end
