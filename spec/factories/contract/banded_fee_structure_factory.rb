FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { Faker::Number.between(from: 1_000, to: 10_000) }
    uplift_fee_per_declaration { Faker::Number.between(from: 50, to: 100) }
    monthly_service_fee { Faker::Number.between(from: 0, to: 20_000) }
    setup_fee { Faker::Number.between(from: 1_000, to: 50_000) }

    trait :with_bands do
      transient do
        declaration_boundaries do
          min = 0

          Array.new(Faker::Number.between(from: 3, to: 4)) do
            max = min + Faker::Number.between(from: 20, to: 200)
            { min:, max: }.tap { min = max + 1 }
          end
        end
      end

      bands do
        declaration_boundaries.map do |boundary|
          association(
            :contract_banded_fee_structure_band,
            banded_fee_structure: instance,
            min_declarations: boundary[:min],
            max_declarations: boundary[:max]
          )
        end
      end
    end
  end
end
