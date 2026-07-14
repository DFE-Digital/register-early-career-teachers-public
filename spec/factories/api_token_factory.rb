FactoryBot.define do
  factory(:api_token, class: "API::Token") do
    lead_provider { nil }
    appropriate_body_period { nil }
    api_third_party { nil }

    description { "A test token" }
    last_used_at { Faker::Time.between(from: 1.month.ago, to: 1.day.ago) }
    token { SecureRandom.base58(32) }

    initialize_with do
      API::Token.find_or_initialize_by(lead_provider:, appropriate_body_period:, token:)
    end

    trait :for_lead_provider do
      association :lead_provider
      description { "A test token for #{lead_provider.name}" }
    end

    trait :for_appropriate_body_period do
      association :appropriate_body_period
      association :api_third_party
      description { "A test token for #{appropriate_body_period.name} and #{api_third_party.name}" }
    end
  end
end
