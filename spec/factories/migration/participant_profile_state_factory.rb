FactoryBot.define do
  factory :migration_participant_profile_state, class: "Migration::ParticipantProfileState" do
    participant_profile { FactoryBot.create(:migration_participant_profile, :ect) }
    cpd_lead_provider { FactoryBot.create(:migration_cpd_lead_provider) }

    state { "active" }

    trait :active do
      state { "active" }
    end

    trait :deferred do
      state { "deferred" }
      reason { "maternity" }
    end

    trait :withdrawn do
      state { "withdrawn" }
      reason { "left_teaching_profession" }
    end
  end
end
