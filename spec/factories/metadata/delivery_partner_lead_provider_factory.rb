FactoryBot.define do
  factory(:delivery_partner_lead_provider_metadata, class: "Metadata::DeliveryPartnerLeadProvider") do
    association :delivery_partner
    association :lead_provider
    contract_period_years do
      years = (2021..Time.current.year).to_a
      random_years = years.shuffle.take(rand(1..years.size))
      random_years.each { FactoryBot.create(:contract_period, year: it) }
      random_years
    end

    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
  end
end
