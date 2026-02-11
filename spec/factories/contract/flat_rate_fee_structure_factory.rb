FactoryBot.define do
  factory(:contract_flat_rate_fee_structure, class: "Contract::FlatRateFeeStructure") do
    recruitment_target { 4500 }
    fee_per_declaration { 1000.00 }
  end
end
