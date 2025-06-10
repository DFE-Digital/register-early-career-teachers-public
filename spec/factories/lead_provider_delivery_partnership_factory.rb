FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    association :active_lead_provider
    association :delivery_partner
  end
end
