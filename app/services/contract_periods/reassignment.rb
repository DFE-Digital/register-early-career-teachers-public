module ContractPeriods
  class Reassignment
    SUCCESSOR_CONTRACT_YEAR = 2024
    attr_reader :training_period

    def initialize(training_period:)
      @training_period = training_period
    end

    def required?
      return false unless training_period&.provider_led_training_programme?
      return false if training_period&.for_mentor?

      contract_period = assigned_contract_period
      return false unless contract_period

      contract_period.payments_frozen?
    end

    def successor_contract_period
      @successor_contract_period ||= ContractPeriod.find_by!(year: SUCCESSOR_CONTRACT_YEAR)
    end

    def assigned_contract_period
      training_period&.contract_period || training_period&.expression_of_interest_contract_period
    end
  end
end
