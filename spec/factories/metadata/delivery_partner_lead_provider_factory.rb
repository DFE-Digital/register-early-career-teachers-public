FactoryBot.define do
  factory(:delivery_partner_lead_provider_metadata, class: "Metadata::DeliveryPartnerLeadProvider") do
    association :delivery_partner
    association :lead_provider
    contract_period_years { (2021..Date.current.year).to_a.sample(rand(1..2)) }

    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
  end
end
