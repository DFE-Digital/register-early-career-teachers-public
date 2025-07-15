FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.number(digits: 6) }
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

    trait :eligible do
      gias_school { association :gias_school, :open, :in_england, :eligible_type, urn: }
    end

    trait :open do
      gias_school { association :gias_school, :open, :in_england, urn: }
    end

    trait :not_open do
      gias_school { association :gias_school, :not_open, :in_england, urn: }
    end

    trait :not_in_england do
      gias_school { association :gias_school, :open, :not_in_england, urn: }
    end

    trait :section_41_approved do
      gias_school { association :gias_school, :open, :section_41, :not_eligible_type, urn: }
    end

    trait :cip_only do
      gias_school { association :gias_school, :open, :in_england, :cip_only_type, urn: }
    end

    trait :not_cip_only do
      gias_school { association :gias_school, :open, :in_england, :not_cip_only_type, urn: }
    end
  end
end
