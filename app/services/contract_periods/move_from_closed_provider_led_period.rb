module ContractPeriods
  class MoveFromClosedProviderLedPeriod
    def initialize(previous_training_period:)
      @previous_training_period = previous_training_period
    end

    def call
      return false unless @previous_training_period&.provider_led_training_programme?

      previous_contract_period&.year.in?([2021, 2022]) &&
        !previous_contract_period.enabled?
    end

  private

    def previous_contract_period
      @previous_training_period&.contract_period ||
        @previous_training_period&.expression_of_interest_contract_period
    end
  end
end
