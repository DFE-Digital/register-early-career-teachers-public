FactoryBot.define do
  sequence(:base_contract_period, 2021)

  factory(:contract_period) do
    year { generate(:base_contract_period) }

    trait :current do
      year { Time.zone.today.year }
    end

    started_on { Date.new(year, 6, 1) }
    finished_on { Date.new(year.next, 5, 31) }

    initialize_with do
      ContractPeriod.find_or_create_by(year:)
    end
  end
end
