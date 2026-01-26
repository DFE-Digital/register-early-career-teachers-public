FactoryBot.define do
  factory(:call_off_contract_banded, class: "CallOffContract::Banded") do
    uplift_target { 100 }
    uplift_fee_per_declaration { 50.00 }
    monthly_service_fee { 1_000.00 }
    setup_fee { 500.00 }

    after(:create) do |banded_contract|
      create_list(:call_off_contract_banded_band, 4, banded_contract:)
    end
  end
end
