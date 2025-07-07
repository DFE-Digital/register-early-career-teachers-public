FactoryBot.define do
  factory :migration_induction_programme, class: "Migration::InductionProgramme" do
    training_programme { :full_induction_programme }
    school_cohort { create(:migration_school_cohort, induction_programme_choice: training_programme) }
  end
end
