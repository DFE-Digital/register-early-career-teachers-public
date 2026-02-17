FactoryBot.define do
  factory(:contract_flat_rate_fee_structure, class: "Contract::FlatRateFeeStructure") do
    recruitment_target { Faker::Number.between(from: 1_000, to: 10_000) }
    fee_per_declaration { Faker::Number.between(from: 500, to: 2_000) }
  end
end
