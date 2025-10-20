FactoryBot.define do
  factory(:appropriate_body) do
    sequence(:name) { |n| "Appropriate Body #{n}" }
    dfe_sign_in_organisation_id { SecureRandom.uuid }
    teaching_school_hub

    trait :istip do
      body_type { "national" }
      name { AppropriateBodies::Search::ISTIP }
      dfe_sign_in_organisation_id { "203606a4-4199-46a9-84e4-56fbc5da2a36" }
    end

    trait :local_authority do
      body_type { "local_authority" }
    end

    trait :national do
      body_type { "national" }
    end

    trait :teaching_school_hub do
      body_type { "teaching_school_hub" }
    end
  end
end
