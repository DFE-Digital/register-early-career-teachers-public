module LeadProviders
  class Active
    attr_reader :lead_provider

    def initialize(lead_provider)
      @lead_provider = lead_provider
    end

    def active_in_contract_period?(contract_period)
      lead_provider.active_lead_providers.exists?(contract_period:)
    end

    def self.in_contract_period(contract_period)
      LeadProvider
        .joins(:active_lead_providers)
        .where(active_lead_providers: { contract_period_id: contract_period.id })
    end
  end
end
