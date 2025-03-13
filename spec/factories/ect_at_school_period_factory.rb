FactoryBot.define do
  sequence(:base_ect_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:ect_at_school_period) do
    association :school, :independent
    association :teacher

    provider_led
    teaching_induction_panel

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }
    working_pattern { WORKING_PATTERNS.keys.sample }

    trait :active do
      started_on { generate(:base_ect_date) + 1.year }
      finished_on { nil }
    end

    trait :provider_led do
      programme_type { 'provider_led' }
      association :lead_provider
    end

    trait :school_led do
      programme_type { 'school_led' }
      lead_provider { nil }
    end

    trait :teaching_induction_panel do
      appropriate_body_type { 'teaching_induction_panel' }
      appropriate_body { nil }
    end

    trait :teaching_school_hub do
      appropriate_body_type { 'teaching_school_hub' }
      appropriate_body { association :appropriate_body }
    end
  end
end
