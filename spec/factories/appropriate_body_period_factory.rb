FactoryBot.define do
  factory(:appropriate_body_period) do
    initialize_with do
      AppropriateBodyPeriod.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Appropriate Body Period #{n}" }
    dfe_sign_in_organisation_id { Faker::Internet.uuid }
    body_type { "teaching_school_hub" }
    association :teaching_school_hub
    association :provisioning_school, factory: :school
    started_on { 1.year.ago }

    trait :inactive do
      dfe_sign_in_organisation_id { nil }
    end

    trait :active do
      association :dfe_sign_in_organisation
    end

    trait :national do
      body_type { "national" }
      association :national_body
      teaching_school_hub { nil }
      provisioning_school { nil }
    end

    trait :istip do
      national
      name { NationalBody::ISTIP }
      association :dfe_sign_in_organisation, :istip
      association :national_body, name: NationalBody::ISTIP
      started_on { Date.new(2011, 8, 31) }
      finished_on { nil }
    end

    trait :esp do
      national
      name { NationalBody::ESP }
      association :dfe_sign_in_organisation, :esp
      association :national_body, name: NationalBody::ESP
      started_on { Date.new(2024, 4, 1) }
      finished_on { nil }
    end

    trait :nta do
      national
      inactive
      name { NationalBody::NTA }
      association :national_body, name: NationalBody::NTA
      started_on { Date.new(2013, 8, 31) }
      finished_on { Date.new(2024, 9, 1) }
    end

    trait :teaching_school_hub do
      body_type { "teaching_school_hub" }
      association :teaching_school_hub
      association :provisioning_school, factory: :school
      started_on { TeachingSchoolHub::APPROPRIATE_BODY[:introduced_on] }
      finished_on { nil }
    end

    trait :teaching_school do
      inactive
      body_type { "teaching_school" }
      association :provisioning_school, factory: :school
      teaching_school_hub { nil }
      started_on { School::APPROPRIATE_BODY[:introduced_on] }
      finished_on { School::APPROPRIATE_BODY[:retired_on] }
    end

    trait :local_authority do
      inactive
      body_type { "local_authority" }
      association :local_authority
      teaching_school_hub { nil }
      provisioning_school { nil }
      started_on { LocalAuthority::APPROPRIATE_BODY[:introduced_on] }
      finished_on { LocalAuthority::APPROPRIATE_BODY[:retired_on] }
    end
  end
end
