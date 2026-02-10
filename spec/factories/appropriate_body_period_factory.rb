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

    trait :national do
      body_type { "national" }
    end

    trait :istip do
      national
      name { AppropriateBody::ISTIP }
      association :dfe_sign_in_organisation, :istip
    end

    trait :esp do
      national
      name { AppropriateBody::ESP }
      association :dfe_sign_in_organisation, :esp
    end

    trait :teaching_school_hub do
      body_type { "teaching_school_hub" }
    end

    trait :local_authority do
      inactive
      body_type { "local_authority" }
      dqt_id { Faker::Internet.uuid }
    end

    trait :with_lead_school do
      association :appropriate_body

      after(:create) do |_period, evaluator|
        FactoryBot.create(:lead_school_period, :ongoing,
                          school: FactoryBot.create(:school),
                          appropriate_body: evaluator.appropriate_body)
      end
    end
  end
end
