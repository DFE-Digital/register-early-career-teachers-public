FactoryBot.define do
  factory :migration_mentor_call_off_contract, class: "Migration::MentorCallOffContract" do
    cohort { FactoryBot.create(:migration_cohort) }
    lead_provider { FactoryBot.create(:migration_lead_provider) }
    version { "1.0" }
    recruitment_target { 5 }
    payment_per_participant { 500 }
  end
end
