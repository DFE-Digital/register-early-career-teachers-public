FactoryBot.define do
  sequence(:base_ect_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:ect_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }

    trait :active do
      started_on { generate(:base_ect_date) + 1.year }
      finished_on { nil }
    end
  end
end
