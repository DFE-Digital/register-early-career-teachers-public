class BackfillContractBandCapacities < ActiveRecord::Migration[8.1]
  def up
    Contract::BandedFeeStructure::Band.all.find_each do |band|
      active_lead_provider = band.banded_fee_structure.contract.active_lead_provider
      capacity = Contract::BandCapacity.where(active_lead_provider:, min_declarations: band.min_declarations).max_by(&:max_declarations)
      # alp_name = active_lead_provider.lead_provider.name
      # year = active_lead_provider.contract_period_year

      if capacity
        if band.max_declarations > capacity.max_declarations
          capacity.update!(max_declarations: band.max_declarations)
          # puts "updated band capacity for #{alp_name} (#{year}) old max[#{capacity.min_declarations}] new max[#{band.max_declarations}]"
        end
      else
        capacity = Contract::BandCapacity.create!(
          active_lead_provider:,
          min_declarations: band.min_declarations,
          max_declarations: band.max_declarations
        )

        # puts "created band capacity for #{alp_name} (#{year}) min[#{band.min_declarations}] max[#{band.max_declarations}]"
      end

      band.update_column(:contract_band_capacity_id, capacity.id)
    end
  end

  def down
    Contract::BandedFeeStructure::Band.update_all(contract_band_capacity_id: nil)
    Contract::BandCapacity.delete_all
  end
end
