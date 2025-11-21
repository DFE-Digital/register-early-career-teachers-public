FactoryBot.define do
  factory(:ect_at_school_period) do
    transient do
      # default start date to be a realistic past date
      # the date aligns sequentially with a previous period if same teacher is passed in
      start_date do
        last_period_end_date = teacher&.ect_at_school_periods&.latest_first&.first&.finished_on
        last_period_end_date&.tomorrow || rand(2.years.ago..6.months.ago)
      end

      # default end date to be a realistic end date
      end_date { (started_on || start_date) + rand(6.months..1.year) }
    end

    teacher { association :teacher, api_ect_training_record_id: SecureRandom.uuid }

    after(:create) do |ect_at_school_period|
      teacher = ect_at_school_period.teacher
      if teacher&.api_ect_training_record_id.blank?
        teacher.update!(api_ect_training_record_id: SecureRandom.uuid)
      end
    end

    independent_school

    started_on { start_date }
    finished_on { end_date }
    email { Faker::Internet.email }
    working_pattern { WORKING_PATTERNS.keys.sample }

    trait :not_started_yet do
      started_on { 2.weeks.from_now }
      finished_on { nil }
    end

    trait :finished do
      started_on { 1.year.ago }
      finished_on { 2.weeks.ago }
    end

    trait :ongoing do
      started_on { 1.year.ago }
      finished_on { nil }
    end

    trait :independent_school do
      association :school, :independent
      national_ab
    end

    trait :state_funded_school do
      association :school, :state_funded
      teaching_school_hub_ab
    end

    trait :local_authority_ab do
      association :school_reported_appropriate_body, :local_authority, factory: :appropriate_body
    end

    trait :national_ab do
      association :school_reported_appropriate_body, :national, factory: :appropriate_body
    end

    trait :teaching_school_hub_ab do
      association :school_reported_appropriate_body, :teaching_school_hub, factory: :appropriate_body
    end

    trait :with_teacher_payments_frozen_year do
      after(:create) do |record|
        ect_payments_frozen_year = FactoryBot.create(:contract_period, year: [2021, 2022].sample).year
        record.teacher.update!(ect_payments_frozen_year:)
      end
    end

    trait :with_training_period do
      transient do
        lead_provider { nil }
        delivery_partner { nil }
        contract_period { nil }
      end

      after(:create) do |ect, evaluator|
        next unless ect.provider_led_training_programme?

        selected_lead_provider = evaluator.lead_provider || FactoryBot.create(:lead_provider)
        selected_delivery_partner = evaluator.delivery_partner || FactoryBot.create(:delivery_partner)
        selected_contract_period = evaluator.contract_period || FactoryBot.create(:contract_period)

        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: selected_lead_provider, contract_period: selected_contract_period)

        lpdp = FactoryBot.create(:lead_provider_delivery_partnership,
                                 active_lead_provider:,
                                 delivery_partner: selected_delivery_partner)

        partnership = FactoryBot.create(:school_partnership,
                                        school: ect.school,
                                        lead_provider_delivery_partnership: lpdp)

        FactoryBot.create(:training_period,
                          ect_at_school_period: ect,
                          school_partnership: partnership,
                          started_on: ect.started_on,
                          finished_on: ect.finished_on)
      end
    end

    trait :with_eoi_only_training_period do
      transient do
        lead_provider { FactoryBot.create(:lead_provider) }
      end

      after(:create) do |ect, evaluator|
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: evaluator.lead_provider)

        FactoryBot.create(
          :training_period,
          :for_ect,
          :with_no_school_partnership,
          ect_at_school_period: ect,
          expression_of_interest: active_lead_provider,
          started_on: ect.started_on + 1.week,
          finished_on: ect.started_on + 1.month
        )
      end
    end
  end
end
