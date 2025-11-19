FactoryBot.define do
  factory(:mentor_at_school_period) do
    transient do
      # default start date to be a realistic past date
      # the date aligns sequentially with a previous period if same teacher is passed in
      start_date do
        last_period_end_date = teacher&.mentor_at_school_periods&.latest_first&.first&.finished_on
        last_period_end_date&.tomorrow || rand(2.years.ago..6.months.ago)
      end

      # default end date to be a realistic end date
      end_date { (started_on || start_date) + rand(6.months..1.year) }
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

    trait :with_training_period do
      transient do
        lead_provider { nil }
        delivery_partner { nil }
        contract_period { nil }
      end

      after(:create) do |mentor, evaluator|
        next unless mentor.provider_led_training_programme?

        selected_lead_provider = evaluator.lead_provider || FactoryBot.create(:lead_provider)
        selected_delivery_partner = evaluator.delivery_partner || FactoryBot.create(:delivery_partner)
        selected_contract_period = evaluator.contract_period || FactoryBot.create(:contract_period)

        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: selected_lead_provider, contract_period: selected_contract_period)

        lpdp = FactoryBot.create(:lead_provider_delivery_partnership,
                                 active_lead_provider:,
                                 delivery_partner: selected_delivery_partner)

        partnership = FactoryBot.create(:school_partnership,
                                        school: mentor.school,
                                        lead_provider_delivery_partnership: lpdp)

        FactoryBot.create(:training_period,
                          mentor_at_school_period: mentor,
                          school_partnership: partnership,
                          started_on: mentor.started_on,
                          finished_on: mentor.finished_on)
      end
    end
  end
end
