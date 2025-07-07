FactoryBot.define do
  factory :migration_participant_profile, class: "Migration::ParticipantProfile" do
    transient do
      user { create(:migration_user) }
    end

    teacher_profile { create(:migration_teacher_profile, user:) }
    participant_identity { create(:migration_participant_identity, user:) }
    school_cohort { create(:migration_school_cohort) }
    schedule { create(:migration_schedule, cohort: school_cohort.cohort) }

    trait :ect do
      type { "ParticipantProfile::ECT" }
    end

    trait :mentor do
      type { "ParticipantProfile::Mentor" }
    end
  end
end
