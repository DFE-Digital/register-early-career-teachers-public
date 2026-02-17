FactoryBot.define do
  factory :contract_banded_fee_structure_band, class: "Contract::BandedFeeStructure::Band" do
    association :banded_fee_structure, factory: :contract_banded_fee_structure
    min_declarations { 1 }
    max_declarations { 100 }
    fee_per_declaration { Faker::Number.between(from: 20, to: 200) }
    output_fee_ratio { 0.75 }
    service_fee_ratio { 0.25 }

    before(:create) do |band|
      band.banded_fee_structure&.bands&.reset
    end
  end
end
