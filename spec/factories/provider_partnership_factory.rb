FactoryBot.define do
  factory(:provider_partnership) do
    association :registration_period
    association :lead_provider
    association :delivery_partner
  end
end
