FactoryBot.define do
  factory(:appropriate_body) do
    initialize_with do
      AppropriateBody.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Appropriate Body #{n}" }

    association :dfe_sign_in_organisation

    trait :istip do
      name { AppropriateBody::ISTIP }
      association :dfe_sign_in_organisation, :istip
    end

    trait :esp do
      name { AppropriateBody::ESP }
      association :dfe_sign_in_organisation, :esp
    end

    trait :with_dsi do
      dfe_sign_in_organisation do
        association :dfe_sign_in_organisation, urn: nil, name:
      end
    end
  end
end
