FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    association :lead_provider_active_period
    association :delivery_partner
  end
end
