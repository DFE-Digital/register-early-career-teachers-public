module ContractPeriods
  class ForECT
    def initialize(started_on:, created_at:)
      @started_on = started_on
      @created_at = created_at
    end

    def call
      ContractPeriod.ongoing_on(@started_on).first ||
        ContractPeriod.ongoing_on(@created_at).first
    end
  end
end
