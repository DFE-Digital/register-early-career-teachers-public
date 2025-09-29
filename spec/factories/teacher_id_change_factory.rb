FactoryBot.define do
  factory :teacher_id_change do
    association :teacher

    api_to_teacher_id { teacher.api_id }

    after(:build) do |teacher_id_change|
      from_teacher = create(:teacher)

      teacher_id_change.api_from_teacher_id = from_teacher.api_id
    end
  end
end
