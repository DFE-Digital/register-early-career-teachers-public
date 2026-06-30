FactoryBot.define do
  factory(:contract) do
    association :active_lead_provider

    for_ittecf_ectp

    trait(:for_ecf) do
      contract_type { "ecf" }
      ecf_contract_version { "1" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure, strategy: :build
      flat_rate_fee_structure { nil }
    end

    trait(:for_ittecf_ectp) do
      contract_type { "ittecf_ectp" }
      ecf_contract_version { "1" }
      ecf_mentor_contract_version { "2" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure, strategy: :build
      association :flat_rate_fee_structure, factory: :contract_flat_rate_fee_structure, strategy: :build
    end

    trait :with_bands_and_band_terms do
      after(:create) do |contract, evaluator|
        active_lead_provider = evaluator.active_lead_provider || contract.active_lead_provider

        FactoryBot.create_list(:active_lead_provider_band, 6,
                               active_lead_provider:).each do |band|
          FactoryBot.create(:contract_banded_fee_structure_band_term,
                            banded_fee_structure: contract.banded_fee_structure,
                            band:)
        end
      end
    end
  end
end
