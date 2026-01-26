FactoryBot.define do
  factory(:call_off_contract_flat_rate, class: "CallOffContract::FlatRate") do
    fee_per_declaration { 100.00 }
  end
end
