FactoryBot.define do
  sequence(:base_training_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:training_period) do
    for_ect
    with_school_partnership
    provider_led

    started_on { generate(:base_training_date) }
    finished_on { started_on + 1.day }

    trait(:school_led) do
      training_programme { 'school_led' }
      school_partnership { nil }
      expression_of_interest { nil }
    end

    trait(:provider_led) do
      training_programme { 'provider_led' }
    end

    trait :with_school_partnership do
      association :school_partnership
    end

    trait :with_expression_of_interest do
      association :expression_of_interest, factory: :active_lead_provider
    end

    trait :with_only_expression_of_interest do
      school_partnership_id { nil }
      association :expression_of_interest, factory: :active_lead_provider
    end

    trait :active do
      finished_on { nil }
    end

    trait :for_ect do
      association :ect_at_school_period
      mentor_at_school_period { nil }
    end

    trait :for_mentor do
      association :mentor_at_school_period
      ect_at_school_period { nil }
    end
  end
end
