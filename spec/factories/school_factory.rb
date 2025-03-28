FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    independent

    trait :independent do
      gias_school { association :gias_school, :independent_school_type, urn: }
    end

    trait :state_funded do
      gias_school { association :gias_school, :state_school_type, urn: }
    end

    trait :provider_led_chosen do
      chosen_programme_type { 'provider_led' }
      association :chosen_lead_provider, factory: :lead_provider
    end

    trait :school_led_chosen do
      chosen_programme_type { 'school_led' }
    end

    trait :local_authority_ab_chosen do
      association :chosen_appropriate_body, :local_authority, factory: :appropriate_body
    end

    trait :national_ab_chosen do
      association :chosen_appropriate_body, :national, factory: :appropriate_body
    end

    trait :teaching_school_hub_ab_chosen do
      association :chosen_appropriate_body, :teaching_school_hub, factory: :appropriate_body
    end
  end
end
