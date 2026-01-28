FactoryBot.define do
  factory(:appropriate_body) do
    initialize_with do
      AppropriateBody.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Appropriate Body #{n}" }

    association :dfe_sign_in_organisation

    trait :national do
      body_type { "national" }
    end

    trait :istip do
      national
      name { NationalBody::ISTIP }
      association :dfe_sign_in_organisation, :istip
    end

    trait :esp do
      national
      name { NationalBody::ESP }
      association :dfe_sign_in_organisation, :esp
    end

    trait :teaching_school_hub do
      body_type { "teaching_school_hub" }
    end

    trait :local_authority do
      inactive
      body_type { "local_authority" }
    end
  end
end

