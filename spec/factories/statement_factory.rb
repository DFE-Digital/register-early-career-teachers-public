FactoryBot.define do
  factory(:statement) do
    active_lead_provider

    api_id { SecureRandom.uuid }
    month { Faker::Number.between(from: 1, to: 12) }
    year { Faker::Number.between(from: 2021, to: Date.current.year) }
    deadline_date { Faker::Date.forward(days: 30) }
    payment_date { Faker::Date.forward(days: 30) }
    output_fee { true }
    open

    trait :open do
      state { :open }
    end

    trait :payable do
      state { :payable }
    end

    trait :paid do
      state { :paid }
    end
  end
end
