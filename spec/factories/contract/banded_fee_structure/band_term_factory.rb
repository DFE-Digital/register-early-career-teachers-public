FactoryBot.define do
  factory :contract_banded_fee_structure_band_term, class: "Contract::BandedFeeStructure::BandTerm" do
    association :banded_fee_structure, factory: :contract_banded_fee_structure

    min_declarations { 1 } # DEPRECATE
    max_declarations { 100 } # DEPRECATE

    fee_per_declaration { Faker::Number.between(from: 20, to: 200) }
    output_fee_ratio { 0.75 }
    service_fee_ratio { 0.25 }

    before(:create) do |band_term|
      # need to factory ALP bands
      band_term.banded_fee_structure&.bands&.reset

      # if band.band.nil? && band.banded_fee_structure
      #   active_lead_provider = band.banded_fee_structure.contract.active_lead_provider
      #   band.band = active_lead_provider.bands.find_or_create_by!(allocation_order: 1) { |b| b.capacity = 100 }
      # end
    end
  end
end
