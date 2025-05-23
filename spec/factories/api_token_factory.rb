FactoryBot.define do
  factory(:api_token, class: "API::Token") do
    association :lead_provider
    description { "A token used for test purposes" }
    last_used_at { Faker::Time.between(from: 1.month.ago, to: 1.day.ago) }
  end
end
