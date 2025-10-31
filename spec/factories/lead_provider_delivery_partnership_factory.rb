FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    association :active_lead_provider
    association :delivery_partner

    trait :for_year do
      transient do
        year { 2025 }
        lead_provider { association :lead_provider }
      end

      active_lead_provider { association :active_lead_provider, :for_year, lead_provider:, year: }
    end
  end
end
