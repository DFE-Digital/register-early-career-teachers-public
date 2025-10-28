FactoryBot.define do
  factory(:mentor_at_school_period) do
    transient do
      # default start date to be a realistic past date
      start_date { 2.years.ago.beginning_of_year.to_date + 1.day }
      # default end date to be a realistic end date
      end_date { (started_on || start_date) + 1.year - 1.day }
    end

    association :school
    teacher { association :teacher, api_mentor_training_record_id: SecureRandom.uuid }

    after(:create) do |mentor_at_school_period|
      teacher = mentor_at_school_period.teacher
      if teacher&.api_mentor_training_record_id.blank?
        teacher.update!(api_mentor_training_record_id: SecureRandom.uuid)
      end
    end

    started_on { start_date }
    finished_on { end_date }
    email { Faker::Internet.email }

    trait :ongoing do
      started_on { 1.year.ago }
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
