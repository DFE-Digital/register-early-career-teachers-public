FactoryBot.define do
  factory(:school_lead_provider_contract_period_metadata, class: "Metadata::SchoolLeadProviderContractPeriod") do
    association :school
    association :contract_period
    association :lead_provider

    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
    expression_of_interest { Faker::Boolean.boolean }
  end
end
