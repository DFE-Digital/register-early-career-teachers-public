class BackfillContractBandCapacities < ActiveRecord::Migration[8.1]
  # NOTE: This migration relies on application models that will be refactored in
  # follow-up PRs.
  def up
    Contract::BandedFeeStructure::Band
      .includes(banded_fee_structure: { contract: :active_lead_provider })
      .find_each do |band|
        active_lead_provider = band.banded_fee_structure.contract.active_lead_provider

        # Band capacities are owned by the ALP and keyed by their lower boundary.
        # The unique index on (active_lead_provider_id, min_declarations) means
        # there can only ever be one capacity row per ALP + min_declarations.
        capacity = Contract::BandCapacity.find_by(
          active_lead_provider:,
          min_declarations: band.min_declarations
        )

        if capacity
          # If another band for the same ALP has the same lower boundary but a
          # higher upper boundary, widen the shared capacity so it covers all
          # declarations seen across every contract for this provider.
          if band.max_declarations > capacity.max_declarations
            capacity.update!(max_declarations: band.max_declarations)
          end
        else
          # No capacity exists yet for this ALP + lower boundary; create it from
          # the band's current boundaries.
          capacity = Contract::BandCapacity.create!(
            active_lead_provider:,
            min_declarations: band.min_declarations,
            max_declarations: band.max_declarations
          )
        end

        # Link the band row to its ALP-wide capacity. update_column skips the
        # Band model validations so the backfill does not trigger the deprecated
        # boundary checks that still read Band#min/max_declarations.
        band.update_column(:contract_band_capacity_id, capacity.id)
      end
  end

  def down
    Contract::BandedFeeStructure::Band.update_all(contract_band_capacity_id: nil)
    Contract::BandCapacity.delete_all
  end
end
