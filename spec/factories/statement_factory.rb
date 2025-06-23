FactoryBot.define do
  factory(:statement) do
    active_lead_provider

    api_id { SecureRandom.uuid }
    sequence(:month) { |n| ((n - 1) % 12) + 1 }
    sequence(:year) do |n|
      available_years = (2021..Date.current.year).to_a
      available_years[(n - 1) % available_years.size]
    end
    deadline_date { Faker::Date.forward(days: 30) }
    payment_date { Faker::Date.forward(days: 30) }
    output_fee { true }
    open

    trait :open do
      status { :open }
    end

    trait :payable do
      status { :payable }
    end

    trait :paid do
      status { :paid }
    end
  end
end
