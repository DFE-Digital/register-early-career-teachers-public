FactoryBot.define do
  factory(:school_partnership) do
    association :lead_provider_delivery_partnership
    association :school

    trait :for_year do
      transient do
        year { 2024 }
        lead_provider { association :lead_provider }
        delivery_partner { association :delivery_partner }
      end

      lead_provider_delivery_partnership do
        association :lead_provider_delivery_partnership,
                    :for_year,
                    year:,
                    lead_provider:,
                    delivery_partner:
      end
    end
  end
end
