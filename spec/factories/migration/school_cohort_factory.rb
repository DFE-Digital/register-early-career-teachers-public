FactoryBot.define do
  factory :migration_school_cohort, class: "Migration::SchoolCohort" do
    school { FactoryBot.create(:ecf_migration_school) }
    cohort { FactoryBot.create(:migration_cohort) }

    induction_programme_choice { :full_induction_programme }

    default_induction_programme { FactoryBot.create(:migration_induction_programme, training_programme: induction_programme_choice, school_cohort: instance) }
  end
end
