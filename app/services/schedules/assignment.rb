module Schedules
  class Assignment
    attr_accessor :period, :training_programme, :started_on, :contract_period_year

    def initialize(contract_period_year:, period:, training_programme:, started_on:)
      @period = period
      @training_programme = training_programme
      @started_on = started_on
      @contract_period_year = contract_period_year
    end

    def call
      return unless provider_led?

      Schedule.find_by(contract_period_year:, identifier:)
    end

  private

    def provider_led?
      training_programme == "provider_led"
    end

    def previous_provider_led_periods
      period.teacher.training_periods.where(training_programme: 'provider_led')
    end

    def most_recent_provider_led_period
      previous_provider_led_periods.latest_first.first
    end

    def most_recent_schedule_identifier
      most_recent_provider_led_period&.schedule&.identifier
    end

    def schedule_date
      return started_on if previous_provider_led_periods.exists?

      [started_on, Time.zone.today].max
    end

    def schedule_month
      case schedule_date
      when june_start..october_end
        'september'
      when november_start..february_end
        'january'
      when march_start..may_end
        'april'
      end
    end

    def next_year
      contract_period_year + 1
    end

    def june_start
      Date.new(contract_period_year, 6, 1)
    end

    def october_end
      november_start - 1
    end

    def november_start
      Date.new(contract_period_year, 11, 1)
    end

    def february_end
      march_start - 1
    end

    def march_start
      Date.new(next_year, 3, 1)
    end

    def may_end
      Date.new(next_year, 5, 31)
    end

    def identifier
      return most_recent_schedule_identifier if most_recent_provider_led_period.present?

      "ecf-standard-#{schedule_month}"
    end
  end
end
