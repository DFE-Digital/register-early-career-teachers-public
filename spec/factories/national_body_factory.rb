FactoryBot.define do
  factory(:national_body) do
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
