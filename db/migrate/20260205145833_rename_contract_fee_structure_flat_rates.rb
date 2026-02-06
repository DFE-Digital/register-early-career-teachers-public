class RenameContractFeeStructureFlatRates < ActiveRecord::Migration[8.0]
  def change
    rename_table :contract_fee_structure_flat_rates, :contract_flat_rate_fee_structures
  end
end
