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
      return previous_contract_period if preserve_previous_contract_period?

      registration_contract_period ||
        raise(
          NoContractPeriodFoundForStartedOnDate,
          "No contract period found for started_on=#{@started_on}"
        )
    end

  private

    def preserve_previous_contract_period?
      return false unless @previous_training_period
      return false unless @previous_training_period.provider_led_training_programme?
      return false unless previous_contract_period
      return false if previous_contract_period.payments_frozen?

      registration_contract_period.present?
    end

    def previous_contract_period
      @previous_training_period.contract_period
    end

    def registration_contract_period
      @registration_contract_period ||= ContractPeriod.for_registration_start_date(@started_on)
    end

    def contract_period_reassignment
      @contract_period_reassignment ||= @reassignment || ContractPeriods::Reassignment.new(
        training_period: @previous_training_period
      )
    end
  end
end
