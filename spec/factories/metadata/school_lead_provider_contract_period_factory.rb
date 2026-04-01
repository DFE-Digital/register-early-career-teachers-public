FactoryBot.define do
  factory(:school_lead_provider_contract_period_metadata, class: "Metadata::SchoolLeadProviderContractPeriod") do
    association :school
    association :contract_period
    association :lead_provider

    to_create do |instance|
      Metadata::Base.bypass_update_restrictions { instance.save! }
    end

    initialize_with do
      Metadata::SchoolLeadProviderContractPeriod.find_or_create_by(school:, contract_period:, lead_provider:)
    end

    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
    expression_of_interest_or_school_partnership { Faker::Boolean.boolean }
  end
end
