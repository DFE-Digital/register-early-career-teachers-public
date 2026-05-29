DEFAULT_CONTRACT_PERIOD_START_MONTH_AND_DAY = [6, 1].freeze
DEFAULT_CONTRACT_PERIOD_FINISH_MONTH_AND_DAY = [5, 31].freeze

CONTRACT_PERIOD_DATES = {
  2021 => { started_on: Date.new(2021, 6, 1), finished_on: Date.new(2022, 5, 31) },
  2022 => { started_on: Date.new(2022, 6, 1), finished_on: Date.new(2023, 5, 31) },
  2023 => { started_on: Date.new(2023, 6, 1), finished_on: Date.new(2024, 5, 31) },
  2024 => { started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 5, 31) },
  2025 => { started_on: Date.new(2025, 6, 1), finished_on: Date.new(2026, 5, 20) },
  2026 => { started_on: Date.new(2026, 6, 15), finished_on: Date.new(2027, 5, 31) },
  2027 => { started_on: Date.new(2027, 6, 1), finished_on: Date.new(2028, 5, 31) },
}.freeze

FactoryBot.define do
  sequence(:base_contract_period, 2021)

  factory(:contract_period) do
    transient do
      current_contract_period_year do
        current_contract_period = CONTRACT_PERIOD_DATES.find do |_year, dates|
          Date.current.in?(dates[:started_on]..dates[:finished_on])
        end

        current_contract_period&.first || Date.current.year
      end

      containing_date { Date.current }
      contract_period_year_containing_date do
        CONTRACT_PERIOD_DATES.find { |_year, dates|
          containing_date.in?(dates[:started_on]..dates[:finished_on])
        }&.first || raise("No contract period for date: #{containing_date}")
      end
    end

    trait(:previous) { year { current_contract_period_year.pred } }
    trait(:current) { year { current_contract_period_year } }
    trait(:next) { year { current_contract_period_year.next } }
    trait(:for_date) { year { contract_period_year_containing_date } }

    year { generate(:base_contract_period) }

    started_on do
      if CONTRACT_PERIOD_DATES.key?(year)
        CONTRACT_PERIOD_DATES[year][:started_on]
      else
        Date.new(year, *DEFAULT_CONTRACT_PERIOD_START_MONTH_AND_DAY)
      end
    end

    finished_on do
      if CONTRACT_PERIOD_DATES.key?(year)
        CONTRACT_PERIOD_DATES[year][:finished_on]
      else
        Date.new(year.next, *DEFAULT_CONTRACT_PERIOD_FINISH_MONTH_AND_DAY)
      end
    end

    enabled { true }
    mentor_funding_enabled { true }
    detailed_evidence_types_enabled { true }
    uplift_fees_enabled { true }

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

    trait :with_extended_schedule do
      after(:create) do |contract_period|
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-extended-september")
      end
    end
  end
end
