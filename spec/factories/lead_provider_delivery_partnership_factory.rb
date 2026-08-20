FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    association :framework_agreement
    association :delivery_partner

    initialize_with do
      LeadProviderDeliveryPartnership.find_or_initialize_by(framework_agreement:, delivery_partner:)
    end

    trait :for_year do
      transient do
        year { 2025 }
        lead_provider { association :lead_provider }
      end

      framework_agreement { association :framework_agreement, :for_year, lead_provider:, year: }
    end
  end
end
