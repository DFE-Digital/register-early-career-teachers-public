FactoryBot.define do
  factory :migration_participant_profile, class: "Migration::ParticipantProfile" do
    transient do
      user { FactoryBot.create(:migration_user) }
    end

    teacher_profile { FactoryBot.create(:migration_teacher_profile, user:) }
    participant_identity { FactoryBot.create(:migration_participant_identity, user:) }
    school_cohort { FactoryBot.create(:migration_school_cohort) }
    schedule { FactoryBot.create(:migration_schedule, cohort: school_cohort.cohort) }

    trait :ect do
      type { "ParticipantProfile::ECT" }
    end

    trait :mentor do
      type { "ParticipantProfile::Mentor" }
    end
  end
end
