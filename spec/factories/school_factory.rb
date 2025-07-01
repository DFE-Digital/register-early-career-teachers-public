FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.number(digits: 6) }
    api_id { SecureRandom.uuid }
    independent

    trait :independent do
      gias_school { association :gias_school, :independent_school_type, urn: }
    end

    trait :state_funded do
      gias_school { association :gias_school, :state_school_type, urn: }
    end

    trait :provider_led_last_chosen do
      last_chosen_training_programme { 'provider_led' }
      association :last_chosen_lead_provider, factory: :lead_provider
    end

    trait :school_led_last_chosen do
      last_chosen_training_programme { 'school_led' }
    end

    trait :local_authority_ab_last_chosen do
      association :last_chosen_appropriate_body, :local_authority, factory: :appropriate_body
    end

    trait :national_ab_last_chosen do
      association :last_chosen_appropriate_body, :national, factory: :appropriate_body
    end

    trait :teaching_school_hub_ab_last_chosen do
      association :last_chosen_appropriate_body, :teaching_school_hub, factory: :appropriate_body
    end
  end
end
