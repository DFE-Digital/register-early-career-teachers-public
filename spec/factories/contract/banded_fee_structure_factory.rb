FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { Faker::Number.between(from: 1_000, to: 10_000) }
    uplift_fee_per_declaration { Faker::Number.between(from: 50, to: 100) }
    monthly_service_fee { Faker::Number.between(from: 0, to: 20_000) }
    setup_fee { Faker::Number.between(from: 1_000, to: 50_000) }

    trait :with_bands_and_band_terms do
      transient do
        active_lead_provider { nil }
      end
      after(:create) do |banded_fee_structure, evaluator|
        alp = evaluator.active_lead_provider || banded_fee_structure.contract.active_lead_provider

        FactoryBot.create_list(:active_lead_provider_band, 4, active_lead_provider: alp).each do |band|
          FactoryBot.create(:contract_banded_fee_structure_band_term,
                            banded_fee_structure:,
                            band:)
        end
      end
    end
  end
end
