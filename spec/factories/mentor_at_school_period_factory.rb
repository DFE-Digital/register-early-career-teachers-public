FactoryBot.define do
  sequence(:base_mentor_date) { |n| 2.years.ago.to_date + (5 * n).days }

  factory(:mentor_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_mentor_date) }
    finished_on { started_on + 5.days }
    email { Faker::Internet.email }

    trait :active do
      started_on { generate(:base_mentor_date) + 1.year }
      finished_on { nil }
    end
  end
end
