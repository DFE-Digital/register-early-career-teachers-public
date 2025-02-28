FactoryBot.define do
  sequence(:base_ect_date) { |n| 2.years.ago.to_date + (5 * n).days }

  factory(:ect_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 5.days }
    email { Faker::Internet.email }

    trait :active do
      finished_on { nil }
    end

    trait :finished do
      started_on { generate(:base_ect_date) - 10.days }
      finished_on { started_on + 1.day }
    end
  end
end
