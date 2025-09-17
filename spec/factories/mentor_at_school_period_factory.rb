FactoryBot.define do
  sequence(:base_mentor_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:mentor_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_mentor_date) }
    finished_on { started_on + 1.year }
    email { Faker::Internet.email }

    trait :ongoing do
      started_on { generate(:base_mentor_date) + 1.year }
      finished_on { nil }
    end
  end
end
