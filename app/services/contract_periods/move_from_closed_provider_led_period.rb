module ContractPeriods
  class MoveFromClosedProviderLedPeriod
    REPLACEMENT_CONTRACT_YEAR = 2024

    def initialize(previous_training_period:)
      @previous_training_period = previous_training_period
    end

    def call
      return false unless @previous_training_period&.provider_led_training_programme?

      contract_period = previous_contract_period
      return false unless contract_period

      contract_period.payments_frozen?
    end

    def self.replacement_contract_period
      @replacement_contract_period ||= ContractPeriod.find_by!(year: REPLACEMENT_CONTRACT_YEAR)
    end

  private

    def previous_contract_period
      @previous_training_period.contract_period ||
        @previous_training_period.expression_of_interest_contract_period
    end
  end
end
