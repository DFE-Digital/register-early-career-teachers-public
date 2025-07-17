module ContractPeriods
  class ForECT
    class NoContractPeriodFoundForStartedOnDate < StandardError; end

    def initialize(started_on:)
      @started_on = started_on
    end

    def call
      ContractPeriod.ongoing_on(@started_on).first ||
        raise(NoContractPeriodFoundForStartedOnDate, "No contract period found for started_on=#{@started_on}")
    end
  end
end
