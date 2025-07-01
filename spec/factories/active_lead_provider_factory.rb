FactoryBot.define do
  factory(:active_lead_provider) do
    association :lead_provider
    association :contract_period
  end
end
