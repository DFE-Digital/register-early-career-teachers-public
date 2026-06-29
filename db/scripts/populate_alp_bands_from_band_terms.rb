# Remodelling the banded fee structure for active lead providers
# Migrate existing values from Contract::BandedFeeStructure::BandTerm to ActiveLeadProvider::Band
#
ActiveLeadProvider::Band.transaction do
  Contract::BandedFeeStructure::BandTerm
    .includes(banded_fee_structure: { contract: :active_lead_provider })
    .find_each do |band_term|
      active_lead_provider = band_term.banded_fee_structure.contract.active_lead_provider
      allocation_order = band_term.banded_fee_structure.band_terms.sort_by(&:min_declarations).index(band_term) + 1
      alp_band = ActiveLeadProvider::Band.find_or_initialize_by(active_lead_provider:, allocation_order:)

      if alp_band.new_record? || band_term.capacity > alp_band.capacity
        alp_band.capacity = band_term.capacity
        alp_band.save!
      end

      band_term.update_column(:band_id, alp_band.id)
    end
end
