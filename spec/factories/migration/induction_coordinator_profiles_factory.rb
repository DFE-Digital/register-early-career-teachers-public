FactoryBot.define do
  factory :migration_induction_coordinator_profile, class: "Migration::InductionCoordinatorProfile" do
    user { FactoryBot.create(:migration_user) }
    schools { [build(:ecf_migration_school)] }
  end
end
