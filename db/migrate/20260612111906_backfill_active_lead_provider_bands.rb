class BackfillActiveLeadProviderBands < ActiveRecord::Migration[8.1]
  def up
    Contract::BandedFeeStructure::Band
      .includes(banded_fee_structure: { contract: :active_lead_provider })
      .find_each do |original_band|
        active_lead_provider = original_band.banded_fee_structure.contract.active_lead_provider

        allocation_order = original_band.banded_fee_structure.bands.sort_by(&:min_declarations).index(original_band) + 1
        alp_band = ActiveLeadProvider::Band.find_or_initialize_by(active_lead_provider:, allocation_order:)

        if alp_band.new_record? || original_band.capacity > alp_band.capacity
          alp_band.capacity = original_band.capacity
          alp_band.save!
        end

        original_band.update_column(:band_id, alp_band.id)
      end
  end

  def down
    Contract::BandedFeeStructure::Band.update_all(band_id: nil)
    ActiveLeadProvider::Band.delete_all
  end
end
