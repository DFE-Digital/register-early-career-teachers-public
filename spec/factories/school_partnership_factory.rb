FactoryBot.define do
  factory(:school_partnership) do
    association :lead_provider_delivery_partnership
    association :school

    initialize_with do
      SchoolPartnership.find_or_initialize_by(lead_provider_delivery_partnership:, school:)
    end

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

    trait :with_framework_agreement do
      transient do
        framework_agreement { association :framework_agreement }
      end

      lead_provider_delivery_partnership do
        association :lead_provider_delivery_partnership,
                    framework_agreement:
      end
    end
  end
end
