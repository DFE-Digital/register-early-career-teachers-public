FactoryBot.define do
  factory :migration_participant_declaration, class: "Migration::ParticipantDeclaration" do
    declaration_type { "started" }
    cohort { FactoryBot.create(:migration_cohort) }
    participant_profile { FactoryBot.create(:migration_participant_profile, :ect) }

    declaration_date { Time.zone.today }

    cpd_lead_provider { create(:migration_cpd_lead_provider) }
    course_identifier { "ecf-induction" }
    user_id { participant_profile.participant_identity.user.id }

    state { :submitted }

    trait :paid do
      state { "paid" }
    end

    trait :clawed_back do
      state { "clawed_back" }
    end

    trait :for_mentor do
      participant_profile { FactoryBot.create(:migration_participant_profile, :mentor) }
      course_identifier { "ecf-mentor" }
    end
  end
end
