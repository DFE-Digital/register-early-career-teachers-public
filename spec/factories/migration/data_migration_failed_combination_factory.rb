FactoryBot.define do
  factory :data_migration_failed_combination, class: "DataMigrationFailedCombination" do
    trn { Faker::Number.unique.number(digits: 7) }
    profile_id { SecureRandom.uuid }
    induction_record_id { SecureRandom.uuid }
    school_urn { Faker::Number.unique.number(digits: 6) }
    cohort_year { 2023 }
    start_date { 1.month.ago }
    end_date { nil }
    induction_status { "active" }
    training_status { "active" }
    schedule_id { SecureRandom.uuid }
    schedule_identifier { "ecf-standard-september" }
    schedule_name { "ECF Standard September" }
    schedule_cohort_year { 2023 }
    preferred_identity_email { Faker::Internet.unique.email }
    failure_message { "Oh oh!" }
    created_at { 12.months.ago }
    updated_at { 6.months.ago }
    ect
    provider_led

    trait :ect do
      profile_type { "ect" }
      mentor_profile_id { SecureRandom.uuid }
    end

    trait :mentor do
      profile_type { "mentor" }
      mentor_profile_id { nil }
    end

    trait :provider_led do
      training_programme { "provider_led" }
      sequence(:lead_provider_name) { |n| "LP #{n}" }
      sequence(:delivery_partner_name) { |n| "DP #{n}" }
    end

    trait :school_led do
      training_programme { "school_led" }
      lead_provider_name { nil }
      delivery_partner_name { nil }
    end
  end
end
