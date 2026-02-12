FactoryBot.define do
  factory(:appropriate_body, class: "AppropriateBodyPeriod") do
    initialize_with do
      AppropriateBodyPeriod.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Appropriate Body Period #{n}" }
    dfe_sign_in_organisation_id { Faker::Internet.uuid }

    trait :inactive do
      dfe_sign_in_organisation_id { nil }
    end

    # Once data migration has started
    trait :active do
      association :dfe_sign_in_organisation
    end

    trait :national do
      body_type { "national" }
    end

    trait :istip do
      national
      name { NationalBody::ISTIP }
    end

    trait :esp do
      national
      name { NationalBody::ESP }
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
