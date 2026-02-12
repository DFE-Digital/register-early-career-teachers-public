FactoryBot.define do
  factory(:dfe_sign_in_organisation) do
    sequence(:name) { |n| "Organisation #{n}" }
    uuid { Faker::Internet.uuid }
    urn { Faker::Number.unique.number(digits: 6) }

    trait :istip do
      name { NationalBody::ISTIP }
      urn { nil }
    end

    trait :esp do
      name { NationalBody::ESP }
      urn { nil }
    end
  end
end
