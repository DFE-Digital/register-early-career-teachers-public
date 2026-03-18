FactoryBot.define do
  factory :migration_pupil_premium, class: "Migration::PupilPremium" do
    association :school, factory: :ecf_migration_school
    start_year { 2024 }
    pupil_premium_incentive { true }
    sparsity_incentive { true }
  end
end
