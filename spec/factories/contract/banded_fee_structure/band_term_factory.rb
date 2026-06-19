FactoryBot.define do
  factory :contract_banded_fee_structure_band_term, class: "Contract::BandedFeeStructure::BandTerm" do
    association :banded_fee_structure, factory: :contract_banded_fee_structure
    association :band, factory: :active_lead_provider_band

    fee_per_declaration { Faker::Number.between(from: 20, to: 200) }
    output_fee_ratio { 0.75 }
    service_fee_ratio { 0.25 }
  end
end
