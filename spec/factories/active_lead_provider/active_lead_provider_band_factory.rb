FactoryBot.define do
  factory :active_lead_provider_band, class: "ActiveLeadProvider::Band" do
    association :active_lead_provider
    capacity { 100 }
  end
end
