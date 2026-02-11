FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { 6000 }
    uplift_fee_per_declaration { 100 }
    monthly_service_fee { 123.45 }
    setup_fee { 149_651 }

    trait :with_bands do
      transient do
        declaration_boundaries do
          [
            { min: 0, max: 100 },
            { min: 101, max: 200 },
            { min: 201, max: 300 }
          ]
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
