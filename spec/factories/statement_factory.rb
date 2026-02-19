FactoryBot.define do
  factory(:statement) do
    transient do
      contract_period { FactoryBot.create(:contract_period) }
    end

    active_lead_provider { association(:active_lead_provider, contract_period:) }
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
      Statement.find_or_initialize_by(active_lead_provider:, month:, year:)
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
