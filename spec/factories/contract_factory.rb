FactoryBot.define do
  factory(:contract) do
    association :active_lead_provider

    for_ittecf_ectp

    trait(:for_ecf) do
      contract_type { "ecf" }
      ecf_contract_version { "1" }
      association :banded_fee_structure, factory: %i[contract_banded_fee_structure with_bands]
      flat_rate_fee_structure_id { nil }
    end

    trait(:for_ittecf_ectp) do
      contract_type { "ittecf_ectp" }
      ecf_contract_version { "1" }
      ecf_mentor_contract_version { "2" }
      association :banded_fee_structure, factory: %i[contract_banded_fee_structure with_bands]
      association :flat_rate_fee_structure, factory: :contract_flat_rate_fee_structure
    end
  end
end
