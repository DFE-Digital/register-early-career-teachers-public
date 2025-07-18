FactoryBot.define do
  sequence(:base_mentor_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:mentor_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_mentor_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }

    trait :active do
      started_on { generate(:base_mentor_date) + 1.year }
      finished_on { nil }
    end

    trait :with_eoi_only_training_period do
      transient do
        lead_provider { FactoryBot.create(:lead_provider) }
      end

      after(:create) do |mentor, evaluator|
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: evaluator.lead_provider)

        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: mentor,
          school_partnership: nil,
          expression_of_interest: active_lead_provider,
          started_on: mentor.started_on + 1.week,
          finished_on: mentor.started_on + 1.month
        )
      end
    end
  end
end
