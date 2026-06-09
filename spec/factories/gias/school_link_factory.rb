FactoryBot.define do
  factory(:gias_school_link, class: GIAS::SchoolLink) do
    association :from_gias_school, factory: :gias_school
    association :to_gias_school, factory: :gias_school

    link_date { Faker::Date.between(from: 2.months.ago, to: Date.yesterday) }
    link_type { GIAS::SchoolLink::LINK_TYPES.sample }

    trait :successor do
      link_type { GIAS::SchoolLink::SUCCESSOR_LINK_TYPES.sample }
    end

    trait :predecessor do
      link_type { GIAS::SchoolLink::PREDECESSOR_LINK_TYPES.sample }
    end

    trait :merged do
      link_type { GIAS::SchoolLink::MERGE_LINK_TYPES.sample }
    end

    trait :successor_split do
      link_type { "Successor - Split School" }
    end

    trait :successor_amalgamated do
      link_type { "Successor - amalgamated" }
    end

    trait :successor_merged do
      link_type { "Successor - merged" }
    end

    trait :successor_unique do
      link_type { "Successor" }
    end

    trait :other do
      link_type { GIAS::SchoolLink::OTHER_LINK_TYPES.sample }
    end
  end
end
