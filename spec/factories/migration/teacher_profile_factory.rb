FactoryBot.define do
  factory :migration_teacher_profile, class: "Migration::TeacherProfile" do
    user { FactoryBot.create(:migration_user) }
    trn { Faker::Number.unique.number(digits: 7) }
  end
end
