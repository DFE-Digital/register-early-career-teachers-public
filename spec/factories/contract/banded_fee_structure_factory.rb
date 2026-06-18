FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { Faker::Number.between(from: 1_000, to: 10_000) }
    uplift_fee_per_declaration { Faker::Number.between(from: 50, to: 100) }
    monthly_service_fee { Faker::Number.between(from: 0, to: 20_000) }
    setup_fee { Faker::Number.between(from: 1_000, to: 50_000) }

    trait :with_band_terms do
      transient do
        declaration_boundaries do
          min = 1

          Array.new(3) do
            max = min + 80
            { min:, max: }.tap { min = max + 1 }
          end
        end
      end

      terms do
        declaration_boundaries.map do |boundary|
          association(
            :contract_banded_fee_structure_band_term,
            banded_fee_structure: instance,
            min_declarations: boundary[:min],
            max_declarations: boundary[:max],
            fee_per_declaration: boundary[:max] + 100,
            strategy: :build
          )
        end
      end
    end
  end
end
