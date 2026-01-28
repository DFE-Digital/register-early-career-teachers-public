FactoryBot.define do
  factory(:call_off_contract_banded, class: "CallOffContract::Banded") do
    recruitment_target { 1_000 }
    uplift_target { 100 }
    uplift_fee_per_declaration { 50.00 }
    monthly_service_fee { 1_000.00 }
    setup_fee { 500.00 }

    after(:create) do |call_off_contract_banded|
      create_list(:call_off_contract_banded_band, 4, call_off_contract_banded:)
    end
  end
end
