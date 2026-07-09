FactoryBot.define do
  factory :active_lead_provider_band, class: "ActiveLeadProvider::Band" do
    association :active_lead_provider
    capacity { 100 }

    allow_creation_when_contracted_or_after_contract_period_start { true }
  end
end
