module LeadProviders
  class Active
    attr_reader :lead_provider

    def initialize(lead_provider)
      @lead_provider = lead_provider
    end

    def active_in_registration_period?(registration_period)
      lead_provider.active_lead_providers.exists?(registration_period:)
    end
  end
end
