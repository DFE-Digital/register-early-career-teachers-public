FactoryBot.define do
  sequence(:base_ect_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:ect_at_school_period) do
    association :teacher

    independent_school
    provider_led

    started_on { generate(:base_ect_date) }
    finished_on { started_on + 1.day }
    email { Faker::Internet.email }
    working_pattern { WORKING_PATTERNS.keys.sample }

    trait :future do
      started_on { 2.weeks.from_now }
      finished_on { nil }
    end

    trait :past do
      started_on { 1.year.ago }
      finished_on { 2.weeks.ago }
    end

    trait :active do
      started_on { generate(:base_ect_date) + 1.year }
      finished_on { nil }
    end

    trait :provider_led do
      training_programme { 'provider_led' }
    end

    trait :school_led do
      training_programme { 'school_led' }
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
                          started_on: ect.started_on)
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
          ect_at_school_period: ect,
          school_partnership: nil,
          expression_of_interest: active_lead_provider,
          started_on: ect.started_on + 1.week,
          finished_on: ect.started_on + 1.month
        )
      end
    end
  end
end
