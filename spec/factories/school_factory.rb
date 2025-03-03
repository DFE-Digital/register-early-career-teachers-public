FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    gias_school { association :gias_school, urn: }

    trait :independent do
      gias_school { association :gias_school, :independent_school_type, urn: }
    end

    trait :state do
      gias_school { association :gias_school, :state_school_type, urn: }
    end

    trait :with_programme_choices do
      chosen_appropriate_body_type { 'teaching_school_hub' }
      chosen_programme_type { 'provider_led' }
      association :chosen_appropriate_body, factory: :appropriate_body
      association :chosen_lead_provider, factory: :lead_provider
    end
  end
end
