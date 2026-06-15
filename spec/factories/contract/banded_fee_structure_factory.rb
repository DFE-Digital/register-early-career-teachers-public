FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { Faker::Number.between(from: 1_000, to: 10_000) }
    uplift_fee_per_declaration { Faker::Number.between(from: 50, to: 100) }
    monthly_service_fee { Faker::Number.between(from: 0, to: 20_000) }
    setup_fee { Faker::Number.between(from: 1_000, to: 50_000) }

    trait :with_bands do
      transient do
        declaration_capacities { [80, 80, 80] }
      end

      bands do
        declaration_capacities.map.with_index do |capacity, index|
          association(
            :contract_banded_fee_structure_band,
            banded_fee_structure: instance,
            priority: index + 1,
            capacity:,
            fee_per_declaration: capacity + index + 100,
            strategy: :build
          )
        end
      end
    end
  end
end
