class BackfillPriorityAndCapacityOnBands < ActiveRecord::Migration[8.1]
  def up
    Contract::BandedFeeStructure.includes(:bands).find_each do |banded_fee_structure|
      previous_capacity = 0

      banded_fee_structure.bands.each.with_index do |band, index|
        band.update_columns(priority: index + 1, capacity: band.max_declarations - previous_capacity)
        previous_capacity = band.max_declarations
      end
    end
  end

  def down
    Contract::BandedFeeStructure::Band.update_all(priority: nil, capacity: nil)
  end
end
