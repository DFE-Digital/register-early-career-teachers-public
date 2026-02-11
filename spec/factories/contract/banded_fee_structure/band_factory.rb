FactoryBot.define do
  factory :contract_banded_fee_structure_band, class: "Contract::BandedFeeStructure::Band" do
    association :banded_fee_structure, factory: :contract_banded_fee_structure
    min_declarations { 1 }
    max_declarations { 100 }
    fee_per_declaration { 50 }
    output_fee_ratio { 0.75 }
    service_fee_ratio { 0.25 }
  end
end
