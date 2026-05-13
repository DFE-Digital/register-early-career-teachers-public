module ContractPeriods
  class ForMentorRegistration
    # NOTE: unlike ECTs, mentors in 2021/2022 contract periods are not migrated
    # to 2024 on re-registration. Those mentors have a funding end date that
    # prevents re-registration, so no reassignment logic is needed here.
    class NoContractPeriodFoundForStartedOnDate < StandardError; end

    def initialize(started_on:, previous_training_period: nil)
      @started_on = started_on
      @previous_training_period = previous_training_period
    end

    def call
      return previous_contract_period if preserve_previous_contract_period?

      ContractPeriod.for_registration_start_date(@started_on) ||
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

      ContractPeriod.for_registration_start_date(@started_on).present?
    end

    def previous_contract_period
      @previous_contract_period ||=
        @previous_training_period.contract_period ||
        @previous_training_period.expression_of_interest&.contract_period
    end
  end
end
