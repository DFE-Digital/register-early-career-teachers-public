FactoryBot.define do
  factory(:contract_fee_structure_flat_rate, class: "Contract::FeeStructure::FlatRate") do
    recruitment_target { 4500 }
    fee_per_declaration { 1000.00 }
  end
end
