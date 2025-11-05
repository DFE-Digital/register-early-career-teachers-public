FactoryBot.define do
  factory(:national_body) do
    initialize_with do
      NationalBody.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "National Body #{n}" }

    trait :istip do
      name { NationalBody::ISTIP }
    end

    trait :esp do
      name { NationalBody::ESP }
    end

    association :dfe_sign_in_organisation
  end
end
