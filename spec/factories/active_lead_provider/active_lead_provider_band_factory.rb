FactoryBot.define do
  factory :active_lead_provider_band, class: "ActiveLeadProvider::Band" do
    association :active_lead_provider
    allocation_order { nil }
    capacity { 100 }
  end
end
