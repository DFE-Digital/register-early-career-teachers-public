FactoryBot.define do
  factory(:active_lead_provider) do
    association :lead_provider
    association :contract_period

    initialize_with do
      ActiveLeadProvider.find_by(lead_provider:, contract_period:) || new(**attributes)
    end
  end
end
