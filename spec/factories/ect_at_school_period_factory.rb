FactoryBot.define do
  sequence(:base_ect_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:ect_at_school_period) do
    association :teacher

    independent_school
    provider_led

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }
    working_pattern { WORKING_PATTERNS.keys.sample }

    trait :active do
      started_on { generate(:base_ect_date) + 1.year }
      finished_on { nil }
    end

    trait :provider_led do
      training_programme { 'provider_led' }
      # association :lead_provider
    end

    trait :school_led do
      training_programme { 'school_led' }
      # lead_provider { nil }
    end

    trait :independent_school do
      association :school, :independent
      national_ab
    end

    trait :state_funded_school do
      association :school, :state_funded
      teaching_school_hub_ab
    end

    trait :local_authority_ab do
      association :school_reported_appropriate_body, :local_authority, factory: :appropriate_body
    end

    trait :national_ab do
      association :school_reported_appropriate_body, :national, factory: :appropriate_body
    end

    trait :teaching_school_hub_ab do
      association :school_reported_appropriate_body, :teaching_school_hub, factory: :appropriate_body
    end
  end
end
