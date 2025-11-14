FactoryBot.define do
  factory(:active_lead_provider) do
    association :lead_provider
    association :contract_period

    initialize_with do
      ActiveLeadProvider.find_or_initialize_by(lead_provider:, contract_period:)
    end

    trait :for_year do
      transient { year { 2025 } }
      contract_period { association :contract_period, year: }
    end
  end
end
