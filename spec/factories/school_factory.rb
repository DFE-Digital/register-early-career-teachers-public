FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    state

    trait :independent do
      gias_school { association :gias_school, :independent_school_type, urn: }
    end

    trait :state do
      gias_school { association :gias_school, :state_school_type, urn: }
    end

    trait :provider_led_chosen do
      chosen_programme_type { 'provider_led' }
      association :chosen_lead_provider, factory: :lead_provider
    end

    trait :school_led_chosen do
      chosen_programme_type { 'school_led' }
    end

    trait :teaching_induction_panel_chosen do
      chosen_appropriate_body_type { 'teaching_induction_panel' }
      chosen_appropriate_body { nil }
    end

    trait :teaching_school_hub_chosen do
      chosen_appropriate_body_type { 'teaching_school_hub' }
      association :chosen_appropriate_body, factory: :appropriate_body
    end
  end
end
