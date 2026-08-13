FactoryBot.define do
  factory(:framework_agreement) do
    association :lead_provider
    association :contract_period

    initialize_with do
      FrameworkAgreement.find_or_initialize_by(lead_provider:, contract_period:)
    end

    trait :for_year do
      transient do
        year { 2025 }
      end
      contract_period { association :contract_period, year: }
    end
  end
end
