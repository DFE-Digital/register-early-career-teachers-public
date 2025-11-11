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
      return most_recent_schedule if previous_provider_led_periods.exists?

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

    def most_recent_schedule
      most_recent_provider_led_period.schedule
    end

    def schedule_date
      [started_on, Time.zone.today].max
    end

    def schedule_month
      case schedule_date
      when june_start..october_end
        'september'
      when november_start..december_end
        'january'
      when january_start..february_end
        'january'
      when march_start..may_end
        'april'
      end
    end

    def contract_period_year
      schedule_date.year
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

    def december_end
      Date.new(contract_period_year, 12, 31)
    end

    def january_start
      Date.new(contract_period_year, 1, 1)
    end

    def february_end
      march_start - 1
    end

    def march_start
      Date.new(contract_period_year, 3, 1)
    end

    def may_end
      Date.new(contract_period_year, 5, 31)
    end

    # TODO: in due course, we will assign non-standard identifiers
    def identifier
      "ecf-standard-#{schedule_month}"
    end
  end
end
