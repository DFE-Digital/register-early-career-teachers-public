FactoryBot.define do
  factory(:lead_provider_active_period) do
    association :lead_provider
    association :registration_period
  end
end
