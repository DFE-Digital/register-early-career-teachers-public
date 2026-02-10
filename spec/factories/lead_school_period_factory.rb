FactoryBot.define do
  factory(:lead_school_period) do
    association :appropriate_body
    association :school

    trait :ongoing do
      started_on { 1.year.ago }
      finished_on { nil }
    end

    trait :finished do
      started_on { 2.years.ago }
      finished_on { 1.year.ago }
    end
  end
end
