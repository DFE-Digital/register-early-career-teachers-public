FactoryBot.define do
  factory(:contract) do
    for_ecf

    trait(:for_ecf) do
      contract_type { "ecf" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure
      flat_rate_fee_structure { nil }
    end

    trait(:for_mentor) do
      contract_type { "ittecf_ectp" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure
      association :flat_rate_fee_structure, factory: :contract_flat_rate_fee_structure
    end
  end
end
