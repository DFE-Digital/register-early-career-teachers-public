FactoryBot.define do
  factory :data_migration_teacher_combination, class: "DataMigrationTeacherCombination" do
    trn { Faker::Number.unique.number(digits: 7) }
    ecf1_ect_profile_id { SecureRandom.uuid }
    ecf1_mentor_profile_id { SecureRandom.uuid }

    ecf1_ect_combinations do
      ["<8aa33fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>",
       "<44433fa7-6a9f-4291-1111-5f9170355871: 222222: 2023: Lead provider B>"]
    end
    ecf2_ect_combinations do
      ["<8aa33fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>"]
    end

    ecf1_mentor_combinations do
      ["<8a234fa7-6a9f-4291-9da5-5f9170355871: 222222: 2049: Lead provider A>",
       "<23232323-6a9f-4291-1111-5f9170355871: 222222: 2023: Lead provider B>"]
    end
    ecf2_mentor_combinations do
      []
    end
  end
end
