FactoryBot.define do
  factory(:active_lead_provider) do
    association :lead_provider
    association :registration_period
  end
end
