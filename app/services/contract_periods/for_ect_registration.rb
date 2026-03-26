module ContractPeriods
  class ForECTRegistration
    class NoContractPeriodFoundForStartedOnDate < StandardError; end

    def initialize(started_on:, previous_training_period: nil, reassigner: nil)
      @started_on = started_on
      @previous_training_period = previous_training_period
      @reassigner = reassigner
    end

    def call
      return contract_period_reassigner.successor_contract_period if contract_period_reassigner.contract_period_closed?

      ContractPeriod.for_registration_start_date(@started_on) ||
        raise(
          NoContractPeriodFoundForStartedOnDate,
          "No contract period found for started_on=#{@started_on}"
        )
    end

  private

    def contract_period_reassigner
      @contract_period_reassigner ||= @reassigner || ContractPeriods::Reassigner.new(
        training_period: @previous_training_period
      )
    end
  end
end
