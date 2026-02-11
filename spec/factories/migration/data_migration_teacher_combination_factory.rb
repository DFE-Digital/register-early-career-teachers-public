FactoryBot.define do
  factory :data_migration_teacher_combination, class: "DataMigrationTeacherCombination" do
    api_id { SecureRandom.uuid }
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
    ecf1_mentorships do
      ["<e491dde6-90c5-473d-b6e2-3b4c63ce90e7: e491dde6-90c5-473d-b6e2-3b4c63ce90e7: ab3d41f5-c42a-4396-80e6-7456f2856253: 2023-02-09: 2023-12-09>",
       "<f6f40352-9141-4b00-bcb7-c5250b9ecfc8: f6f40352-9141-4b00-bcb7-c5250b9ecfc8: 9246931b-bd85-445f-aea6-8802c124d9d9: 2023-13-09: >"]
    end
    ecf2_mentorships do
      ["<f6f40352-9141-4b00-bcb7-c5250b9ecfc8: f6f40352-9141-4b00-bcb7-c5250b9ecfc8: 9246931b-bd85-445f-aea6-8802c124d9d9: 2023-13-09: >"]
    end
  end
end
