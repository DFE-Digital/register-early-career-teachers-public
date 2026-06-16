class AddUpliftTargetRatioToContractBandedFeeStructures < ActiveRecord::Migration[8.0]
  def change
    add_column :contract_banded_fee_structures,
               :uplift_target_ratio,
               :decimal,
               precision: 5,
               scale: 4
  end
end
