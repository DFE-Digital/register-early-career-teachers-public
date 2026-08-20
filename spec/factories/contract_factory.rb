FactoryBot.define do
  factory(:contract) do
    association :framework_agreement

    for_ittecf_ectp

    trait(:for_ecf) do
      contract_type { "ecf" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure, strategy: :build
      flat_rate_fee_structure { nil }
    end

    trait(:for_ittecf_ectp) do
      contract_type { "ittecf_ectp" }
      association :banded_fee_structure, factory: :contract_banded_fee_structure, strategy: :build
      association :flat_rate_fee_structure, factory: :contract_flat_rate_fee_structure, strategy: :build
    end

    trait :with_bands_and_band_terms do
      after(:create) do |contract, evaluator|
        framework_agreement = evaluator.framework_agreement || contract.framework_agreement

        FactoryBot.create_list(:framework_agreement_band, 6,
                               framework_agreement:).each do |band|
          FactoryBot.create(:contract_banded_fee_structure_band_term,
                            banded_fee_structure: contract.banded_fee_structure,
                            band:)
        end
      end
    end
  end
end
