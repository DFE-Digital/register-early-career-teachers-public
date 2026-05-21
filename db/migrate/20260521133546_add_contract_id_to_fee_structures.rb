class AddContractIdToFeeStructures < ActiveRecord::Migration[8.1]
  def change
    add_reference :contract_banded_fee_structures, :contract, foreign_key: true
    add_reference :contract_flat_rate_fee_structures, :contract, foreign_key: true
  end
end
