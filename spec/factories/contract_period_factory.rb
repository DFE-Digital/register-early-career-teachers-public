FactoryBot.define do
  sequence(:base_contract_period, 2021)

  # rubocop:disable Lint/ConstantDefinitionInBlock
  START_MONTH_AND_DAY = [6, 1].freeze
  FINISH_MONTH_AND_DAY = [5, 31].freeze
  # rubocop:enable Lint/ConstantDefinitionInBlock

  factory(:contract_period) do
    transient do
      current_contract_period_year do
        current_year = Time.zone.today.year

        ((current_year.pred)..current_year.next).find do
          Date.current.in?(Date.new(it, *START_MONTH_AND_DAY)..Date.new(it + 1, *FINISH_MONTH_AND_DAY))
        end
      end
    end

    year { generate(:base_contract_period) }

    trait(:previous) { year { current_contract_period_year.pred } }
    trait(:current) { year { current_contract_period_year } }
    trait(:next) { year { current_contract_period_year.next } }

    enabled { true }
    started_on { Date.new(year, *START_MONTH_AND_DAY) }
    finished_on { Date.new(year.next, *FINISH_MONTH_AND_DAY) }
    mentor_funding_enabled { true }
    detailed_evidence_types_enabled { true }

    initialize_with do
      ContractPeriod.find_or_create_by(year:)
    end

    trait :with_schedules do
      after(:create) do |contract_period|
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
      end
    end

    trait :with_payments_frozen do
      payments_frozen_at { Time.zone.now }
    end
  end
end
