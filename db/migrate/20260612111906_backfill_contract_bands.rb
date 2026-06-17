class BackfillContractBands < ActiveRecord::Migration[8.1]
  # NOTE: This migration relies on the Contract::BandedFeeStructure::Band model that will be renamed in a follow-up PR.
  def up
    Contract::BandedFeeStructure::Band
      .includes(banded_fee_structure: { contract: :active_lead_provider })
      .find_each do |original_band|
        active_lead_provider = original_band.banded_fee_structure.contract.active_lead_provider

        # Bucket position within its fee structure (like #letter):
        #
        allocation_order = original_band.banded_fee_structure.bands.sort_by(&:min_declarations).index(original_band) + 1

        # Bucket volume:
        #   81 - 1 + 1 = 81
        #   162 - 82 + 1 = 81
        #   243 - 163 + 1 = 81
        #
        capacity = original_band.max_declarations - original_band.min_declarations + 1

        # The ALP-wide band at this position
        #
        contract_band = Contract::Band.find_or_initialize_by(active_lead_provider:, allocation_order:)

        # Keep the largest bucket
        #
        if contract_band.new_record? || capacity > contract_band.capacity
          contract_band.capacity = capacity
          contract_band.save!
        end

        # Link the old band to the new ALP-wide band
        #
        original_band.update_column(:contract_band_id, contract_band.id)
      end
  end

  def down
    Contract::BandedFeeStructure::Band.update_all(contract_band_id: nil)
    Contract::Band.delete_all
  end
end
