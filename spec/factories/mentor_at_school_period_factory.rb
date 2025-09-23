FactoryBot.define do
  sequence(:base_mentor_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:mentor_at_school_period) do
    association :school
    association :teacher

    started_on { generate(:base_mentor_date) }
    finished_on { started_on + 1.year }
    email { Faker::Internet.email }

    trait :ongoing do
      started_on { generate(:base_mentor_date) + 1.year }
      finished_on { nil }
    end

    trait :with_teacher_payments_frozen_year do
      after(:create) do |record|
        mentor_payments_frozen_year = FactoryBot.create(:contract_period, year: [2021, 2022].sample).year
        record.teacher.update!(mentor_payments_frozen_year:)
      end
    end
  end
end
