FactoryBot.define do
  factory :migration_call_off_contract, class: "Migration::CallOffContract" do
    cohort { FactoryBot.create(:migration_cohort) }
    lead_provider { FactoryBot.create(:migration_lead_provider) }
    version { "1.0" }
    uplift_target { 100 }
    uplift_amount { 1000 }
    recruitment_target { 10 }
    set_up_fee { 500 }
    revised_target { 15 }
    monthly_service_fee { 200 }
  end
end
