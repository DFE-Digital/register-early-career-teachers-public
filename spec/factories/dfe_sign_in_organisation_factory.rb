FactoryBot.define do
  factory(:dfe_sign_in_organisation) do
    initialize_with do
      DfESignInOrganisation.find_or_initialize_by(uuid:)
    end

    sequence(:name) { |n| "Organisation #{n}" }
    uuid { Faker::Internet.uuid }
    urn { Faker::Number.unique.number(digits: 6) }

    trait :istip do
      name { AppropriateBody::ISTIP }
      urn { nil }
    end

    trait :esp do
      name { AppropriateBody::ESP }
      urn { nil }
    end
  end
end
