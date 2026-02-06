FactoryBot.define do
  factory(:appropriate_body_period) do
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

    trait :istip do
      name { AppropriateBody::ISTIP }
      body_type { "national" }
    end

    trait :esp do
      name { AppropriateBody::ESP }
      body_type { "national" }
    end

    trait :teaching_school_hub do
      body_type { "teaching_school_hub" }
    end

    trait :local_authority do
      inactive
      body_type { "local_authority" }
      dqt_id { Faker::Internet.uuid }
    end
  end
end
