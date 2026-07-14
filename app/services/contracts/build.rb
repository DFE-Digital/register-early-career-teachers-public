module Contracts
  class Build
    attr_reader :active_lead_provider

    def initialize(active_lead_provider:)
      @active_lead_provider = active_lead_provider
    end

    def call
      contract = active_lead_provider.contracts.build
      banded_fee_structure = contract.build_banded_fee_structure

      previous_terms_by_band_id = previous_band_terms.index_by(&:band_id)

      active_lead_provider.bands.each do |alp_band|
        previous_term = previous_terms_by_band_id[alp_band.id]

        banded_fee_structure.band_terms.build(
          band: alp_band,
          fee_per_declaration: previous_term&.fee_per_declaration,
          output_fee_ratio: previous_term&.output_fee_ratio,
          service_fee_ratio: previous_term&.service_fee_ratio
        )
      end

      contract.build_flat_rate_fee_structure
      contract
    end

  private

    def previous_band_terms
      return [] unless previous_contract&.banded_fee_structure

      previous_contract.banded_fee_structure.band_terms.to_a
    end

    def previous_contract
      active_lead_provider
        .contracts
        .most_recent_first
        .includes(banded_fee_structure: { band_terms: :band })
        .first
    end
  end
end
