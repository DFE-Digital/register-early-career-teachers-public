FactoryBot.define do
  factory(:school) do
    urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    gias_school { association :gias_school, urn: }

    trait :independent do
      gias_school { association :gias_school, urn:, type_name: GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.sample }
    end
  end
end
