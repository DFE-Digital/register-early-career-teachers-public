FactoryBot.define do
  sequence(:base_contract_period, 2021)

  factory(:contract_period) do
    year { generate(:base_contract_period) }

    trait :current do
      year { Time.zone.today.year }
    end

    enabled { true }
    started_on { Date.new(year, 6, 1) }
    finished_on { Date.new(year.next, 5, 31) }

    initialize_with do
      ContractPeriod.find_or_create_by(year:)
    end

    trait :with_schedules do
      after(:create) do |contract_period|
        FactoryBot.create(:schedule, contract_period:, identifier: 'ecf-standard-september')
        FactoryBot.create(:schedule, contract_period:, identifier: 'ecf-standard-january')
        FactoryBot.create(:schedule, contract_period:, identifier: 'ecf-standard-april')
      end
    end
  end
end
