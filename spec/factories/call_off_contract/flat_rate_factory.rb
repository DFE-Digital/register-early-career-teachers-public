FactoryBot.define do
  factory(:call_off_contract_flat_rate, class: "CallOffContract::FlatRate") do
    recruitment_target { 1_000 }
    fee_per_declaration { 100.00 }
  end
end
