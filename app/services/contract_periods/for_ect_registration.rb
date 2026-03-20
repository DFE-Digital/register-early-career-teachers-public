module ContractPeriods
  class ForECTRegistration
    class NoContractPeriodFoundForStartedOnDate < StandardError; end

    def initialize(started_on:, previous_training_period: nil)
      @started_on = started_on
      @previous_training_period = previous_training_period
    end

    def call
      return contract_period_2024 if move_from_closed_provider_led_period?

      ContractPeriod.for_registration_start_date(@started_on) ||
        raise(
          NoContractPeriodFoundForStartedOnDate,
          "No contract period found for started_on=#{@started_on}"
        )
    end

  private

    def move_from_closed_provider_led_period?
      ContractPeriods::MoveFromClosedProviderLedPeriod
        .new(previous_training_period: @previous_training_period)
        .call
    end

    def contract_period_2024
      ContractPeriod.find_by!(year: 2024)
    end
  end
end
