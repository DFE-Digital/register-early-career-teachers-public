FactoryBot.define do
  sequence(:base_training_date) { |n| 3.years.ago.to_date + (2 * n).days }

  factory(:training_period) do
    for_ect
    with_school_partnership
    with_schedule
    provider_led

    started_on { generate(:base_training_date) }
    finished_on { started_on + 1.day }

    trait :not_started_yet do
      started_on { 2.weeks.from_now }
      finished_on { nil }
    end

    trait :finished do
      started_on  { ect_at_school_period&.started_on || 1.year.ago }
      finished_on { ect_at_school_period&.started_on&.+(1.month) || 2.weeks.ago }
    end

    trait(:school_led) do
      training_programme { 'school_led' }
      school_partnership { nil }
      expression_of_interest { nil }
      schedule { nil }
    end

    trait(:provider_led) do
      training_programme { 'provider_led' }
    end

    trait :with_school_partnership do
      transient do
        teacher_period { ect_at_school_period.presence || mentor_at_school_period }
      end

      school_partnership { association :school_partnership, school: teacher_period.school }
    end

    trait :with_schedule do
      transient do
        schedule { FactoryBot.build(:schedule, contract_period: contract_period || expression_of_interest_contract_period) }
      end

      after(:build) do |training_period, evaluator|
        training_period.schedule = evaluator.schedule
      end
    end

    trait :with_no_school_partnership do
      school_partnership { nil }
    end

    trait :with_expression_of_interest do
      after(:build) do |training_period|
        training_period.expression_of_interest = FactoryBot.create(:active_lead_provider,
                                                                   contract_period: training_period.contract_period ||
                                                                   FactoryBot.create(:contract_period, :current))
      end
    end

    trait :with_only_expression_of_interest do
      school_partnership { nil }
      association :expression_of_interest, factory: :active_lead_provider

      with_schedule
    end

    trait :ongoing do
      finished_on { nil }
    end

    trait :for_ect do
      association :ect_at_school_period
      mentor_at_school_period { nil }
    end

    trait :for_mentor do
      association :mentor_at_school_period
      ect_at_school_period { nil }
    end

    trait :withdrawn do
      withdrawn_at { Faker::Date.between(from: started_on, to: (finished_on || Date.current)) }
      withdrawal_reason { TrainingPeriod.withdrawal_reasons.values.sample }
    end

    trait :deferred do
      deferred_at { Faker::Date.between(from: started_on, to: (finished_on || Date.current)) }
      deferral_reason { TrainingPeriod.deferral_reasons.values.sample }
    end
  end
end
