FactoryBot.define do
  sequence(:base_training_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:training_period) do
    for_ect
    association :provider_partnership

    started_on { generate(:base_training_date) }
    finished_on { started_on + 1.day }

    association :expression_of_interest, factory: :lead_provider_active_period

    trait :with_confirmed_school_partnership do
      expression_of_interest { nil }
      association :confirmed_school_partnership, factory: :school_partnership
    end

    trait :active do
      finished_on { nil }
    end

    trait(:for_ect) do
      association :ect_at_school_period
      mentor_at_school_period { nil }
    end

    trait(:for_mentor) do
      association :mentor_at_school_period
      ect_at_school_period { nil }
    end
  end
end
