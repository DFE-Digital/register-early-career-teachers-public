FactoryBot.define do
  factory :ecf_migration_school_mentor, class: "Migration::SchoolMentor" do
    school { FactoryBot.create(:ecf_migration_school) }
    participant_profile { FactoryBot.create(:migration_participant_profile, :ect) }
    preferred_identity { participant_profile.participant_identity }
    created_at { 9.months.ago }
    updated_at { 6.months.ago }
  end
end
