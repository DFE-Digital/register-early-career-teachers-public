FactoryBot.define do
  factory(:statement) do
    transient do
      contract_period { FactoryBot.create(:contract_period) }
      active_lead_provider { association(:active_lead_provider, contract_period:) }
    end

    contract { association(:contract, :for_ittecf_ectp, active_lead_provider:) }
    api_id { SecureRandom.uuid }
    sequence(:month) { |n| ((n - 1) % 12) + 1 }
    sequence(:year) do |n|
      available_years = (2021..Date.current.year).to_a
      available_years[(n - 1) % available_years.size]
    end
    deadline_date { Faker::Date.forward(days: 30) }
    payment_date { Faker::Date.forward(days: 30) }
    output_fee

    initialize_with do
      Statement
        .joins(:contract)
        .where(contracts: { active_lead_provider_id: active_lead_provider.id })
        .find_or_initialize_by(
          month:,
          year:
        ) do |statement|
          statement.contract = contract
        end
    end

    trait :open do
      status { :open }
    end

    trait :payable do
      status { :payable }
    end

    trait :paid do
      status { :paid }
    end

    trait :output_fee do
      fee_type { "output" }
    end

    trait :service_fee do
      fee_type { "service" }
    end
  end
end
