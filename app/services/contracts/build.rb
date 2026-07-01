module Contracts
  class Build
    attr_reader :active_lead_provider

    def initialize(active_lead_provider:)
      @active_lead_provider = active_lead_provider
    end

    def call
      contract = active_lead_provider.contracts.build
      banded_fee_structure = contract.build_banded_fee_structure

      # Temporarily seed bands from the previous contract's band_structure until
      # ActiveLeadProvider::Band is implemented and can provide this data directly.
      existing_contract = active_lead_provider.contracts
                            .joins(banded_fee_structure: :bands)
                            .includes(banded_fee_structure: :bands)
                            .first

      if existing_contract&.banded_fee_structure&.bands&.any?
        existing_contract.banded_fee_structure.bands.each do |band|
          banded_fee_structure.bands.build(band.attributes.slice("min_declarations", "max_declarations",
                                                                 "fee_per_declaration", "output_fee_ratio", "service_fee_ratio"))
        end
      else
        banded_fee_structure.bands.build
      end

      contract.build_flat_rate_fee_structure
      contract
    end
  end
end
