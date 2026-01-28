FactoryBot.define do
  factory(:call_off_contract_banded_band, class: "CallOffContract::Banded::Band") do
    sequence(:min_declarations) { |n| (n - 1) * 10 + 1 }
    sequence(:max_declarations) { |n| n * 10 }
    fee_per_declaration { 100.00 }
    output_fee_ratio { 0.7 }
    service_fee_ratio { 0.3 }
  end
end
