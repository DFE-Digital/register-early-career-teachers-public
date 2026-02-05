FactoryBot.define do
  factory(:contract) do
    for_ecf

    trait(:for_ecf) do
      contract_type { "ecf" }
      association :contract_banded_fee_structure
      contract_flat_rate_fee_structure { nil }
    end

    trait(:for_mentor) do
      contract_type { "ittecf_ectp" }
      association :contract_flat_rate_fee_structure
      contract_banded_fee_structure { nil }
    end
  end
end
