FactoryBot.define do
  factory(:available_provider_pairing) do
    association :active_lead_provider
    association :delivery_partner
  end
end
