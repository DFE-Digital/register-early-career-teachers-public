module LeadProviders
  class Active
    attr_reader :lead_provider

    def initialize(lead_provider)
      @lead_provider = lead_provider
    end

    def active_in_contract_period?(contract_period)
      lead_provider.framework_agreements.exists?(contract_period:)
    end

    def framework_agreements(contract_period)
      lead_provider.framework_agreements.where(contract_period:)
    end

    def self.in_contract_period(contract_period)
      LeadProvider
        .joins(:framework_agreements)
        .where(framework_agreements: { contract_period_year: contract_period.id })
    end
  end
end
