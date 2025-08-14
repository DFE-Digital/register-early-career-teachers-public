FactoryBot.define do
  factory(:school_partnership) do
    association :lead_provider_delivery_partnership
    association :school

    trait :with_school_metadata do
      school do
        lead_provider = lead_provider_delivery_partnership.lead_provider
        contract_period = lead_provider_delivery_partnership.contract_period

        association :school, :with_metadata, lead_provider:, contract_period:
      end
    end
  end
end
