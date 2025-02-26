FactoryBot.define do
  sequence(:base_ect_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:ect_at_school_period) do
    association :school
    association :teacher
    association :lead_provider
    association :appropriate_body

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }
    programme_type { PROGRAMME_TYPES.keys.sample }
    working_pattern { WORKING_PATTERNS.keys.sample }

    trait :active do
      started_on { generate(:base_ect_date) + 1.year }
      finished_on { nil }
    end
  end
end
