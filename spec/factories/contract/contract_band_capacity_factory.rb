FactoryBot.define do
  factory :contract_band_capacity, class: "Contract::BandCapacity" do
    association :active_lead_provider
    min_declarations { 1 }
    max_declarations { 100 }
  end
end
