module ContractPeriods
  class ForECTRegistration
    class NoContractPeriodFoundForStartedOnDate < StandardError; end

    def initialize(started_on:, previous_training_period: nil, reassignment: nil)
      @started_on = started_on
      @previous_training_period = previous_training_period
      @reassignment = reassignment
    end

    def call
      return contract_period_reassignment.successor_contract_period if contract_period_reassignment.required?

      ContractPeriod.for_registration_start_date(@started_on) ||
        raise(
          NoContractPeriodFoundForStartedOnDate,
          "No contract period found for started_on=#{@started_on}"
        )
    end

  private

    def contract_period_reassignment
      @contract_period_reassignment ||= @reassignment || ContractPeriods::Reassignment.new(
        training_period: @previous_training_period
      )
    end
  end
end
