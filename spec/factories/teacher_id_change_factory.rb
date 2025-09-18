FactoryBot.define do
  factory :teacher_id_change do
    association :teacher

    to_teacher_id { teacher.api_user_id }

    after(:build) do |teacher_id_change|
      from_teacher = create(:teacher)

      teacher_id_change.from_teacher_id = from_teacher.api_user_id
    end
  end
end
