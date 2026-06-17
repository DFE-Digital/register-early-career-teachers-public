FactoryBot.define do
  factory :contract_band, class: "Contract::Band" do
    association :active_lead_provider
    allocation_order { 1 }
    capacity { 100 }
  end
end
