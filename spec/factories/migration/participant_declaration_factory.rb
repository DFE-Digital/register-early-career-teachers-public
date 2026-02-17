FactoryBot.define do
  factory :migration_participant_declaration, class: "Migration::ParticipantDeclaration" do
    ect
    cpd_lead_provider { FactoryBot.create(:migration_cpd_lead_provider) }
    cohort { FactoryBot.create(:migration_cohort) }

    declaration_type { "started" }
    declaration_date { Faker::Date.between(from: 2.years.ago, to: 1.day.ago) }
    course_identifier { "ecf-induction" }
    evidence_held { "other" }
    state { "submitted" }
    sparsity_uplift { true }
    pupil_premium_uplift { true }
    user_id { participant_profile.participant_identity.user.id }

    trait :ect do
      type { "ParticipantDeclaration::ECT" }
      participant_profile { FactoryBot.create(:migration_participant_profile, :ect, cohort:) }
    end

    trait :mentor do
      type { "ParticipantDeclaration::Mentor" }
      participant_profile { FactoryBot.create(:migration_participant_profile, :mentor, cohort:) }
    end

    trait :billable do
      state { "payable" }

      after(:create) do |participant_declaration, _evaluator|
        create(:migration_statement_line_item, participant_declaration:, state: participant_declaration.state)
      end
    end

    trait :refundable do
      state { "clawed_back" }

      after(:create) do |participant_declaration, _evaluator|
        create(:migration_statement_line_item, participant_declaration:, state: "paid")
        create(:migration_statement_line_item, participant_declaration:, state: participant_declaration.state)
      end
    end
  end
end
