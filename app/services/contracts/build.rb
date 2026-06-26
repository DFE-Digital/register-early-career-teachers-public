module Contracts
  class Build
    attr_reader :active_lead_provider

    def initialize(active_lead_provider:)
      @active_lead_provider = active_lead_provider
    end

    def call
      contract = active_lead_provider.contracts.build
      banded_fee_structure = contract.build_banded_fee_structure

      if active_lead_provider.banded?
        existing_terms = most_recent_band_terms_by_band_id
        active_lead_provider.bands.each do |band|
          prior_band_terms = existing_terms[band.id]
          if prior_band_terms
            banded_fee_structure.bands.build(prior_band_terms.slice("band_id", "fee_per_declaration", "output_fee_ratio", "service_fee_ratio"))
          else
            banded_fee_structure.bands.build(band:)
          end
        end
      else
        raise StandardError, "No bands for active_lead_provider for #{active_lead_provider.id}"
      end

      contract.build_flat_rate_fee_structure
      contract
    end

  private

    def most_recent_band_terms_by_band_id
      most_recent_contract_with_bands&.banded_fee_structure&.bands&.index_by(&:band_id) || {}
    end

    def most_recent_band_terms
      most_recent_contract_with_bands&.banded_fee_structure&.bands || []
    end

    def most_recent_contract_with_bands
      active_lead_provider.contracts
        .joins(banded_fee_structure: :bands)
        .includes(banded_fee_structure: :bands)
        .order(created_at: :desc)
        .first
    end
  end
end
