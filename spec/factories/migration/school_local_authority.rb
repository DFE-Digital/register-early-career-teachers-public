FactoryBot.define do
  factory :ecf_migration_school_local_authority, class: "Migration::SchoolLocalAuthority" do
    association :school, factory: :ecf_migration_school
    association :local_authority, factory: :ecf_migration_local_authority

    start_year { 2022 }
  end
end
