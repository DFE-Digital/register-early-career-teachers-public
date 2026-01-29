FactoryBot.define do
  factory :migration_induction_programme, class: "Migration::InductionProgramme" do
    training_programme { :full_induction_programme }
    school_cohort { FactoryBot.create(:migration_school_cohort, induction_programme_choice: training_programme) }

    trait :provider_led do
      training_programme { :full_induction_programme }
      core_induction_programme { nil }
      partnership { FactoryBot.create(:migration_partnership, cohort: school_cohort.cohort, school: school_cohort.school) }
    end

    trait :school_led do
      training_programme { :core_induction_programme }
      core_induction_programme { FactoryBot.create(:migration_core_induction_programme) }
      partnership { nil }
    end
  end
end
