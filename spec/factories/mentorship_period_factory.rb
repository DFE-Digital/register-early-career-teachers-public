FactoryBot.define do
  sequence(:base_mentorship_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:mentorship_period) do
    started_on { generate(:base_mentorship_date) }
    finished_on { started_on + 1.day }

    trait :active do
      finished_on { nil }
    end
  end
end
