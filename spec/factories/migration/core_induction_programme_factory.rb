FactoryBot.define do
  factory :migration_core_induction_programme, class: "Migration::CoreInductionProgramme" do
    sequence(:name) { |n| "Migration Core Induction Programme #{n}" }
  end
end
