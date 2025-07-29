FactoryBot.define do
  factory(:active_lead_provider) do
    association :lead_provider
    association :contract_period

    initialize_with do
      ActiveLeadProvider.find_or_create_by(lead_provider:, contract_period:)
    end
  end
end
