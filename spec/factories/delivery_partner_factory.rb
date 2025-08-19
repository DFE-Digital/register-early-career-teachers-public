FactoryBot.define do
  factory(:delivery_partner) do
    sequence(:name) { |n| "#{Faker::University.name} Delivery Partner #{n}" }

    trait :with_metadata do
      transient do
        lead_provider { create(:lead_provider) }
      end

      after(:create) do |delivery_partner, evaluator|
        create(:delivery_partner_lead_provider_metadata,
               delivery_partner:,
               lead_provider: evaluator.lead_provider)
      end
    end
  end
end
