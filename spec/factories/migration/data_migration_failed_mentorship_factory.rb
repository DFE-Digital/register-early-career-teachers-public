FactoryBot.define do
  factory :data_migration_failed_mentorship, class: "DataMigrationFailedMentorship" do
    ect_participant_profile_id { SecureRandom.uuid }
    mentor_participant_profile_id { SecureRandom.uuid }
    started_on { 1.year.ago.to_date }
    finished_on { Date.current }
    ecf_start_induction_record_id { SecureRandom.uuid }
    ecf_end_induction_record_id { ecf_start_induction_record_id }
    failure_message { "Oops!" }

    trait :ongoing do
      finished_on { nil }
    end
  end
end
