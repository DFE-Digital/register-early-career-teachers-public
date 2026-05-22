class AddContractIdToFeeStructures < ActiveRecord::Migration[8.1]
  def change
    add_reference :contract_banded_fee_structures, :contract, null: true, foreign_key: true
    add_reference :contract_flat_rate_fee_structures, :contract, null: true, foreign_key: true

    add_index :contract_banded_fee_structures, :contract_id, unique: true, where: "contract_id IS NOT NULL", name: "index_banded_fee_structures_on_contract_id_unique_not_null"
    add_index :contract_flat_rate_fee_structures, :contract_id, unique: true, where: "contract_id IS NOT NULL", name: "index_flat_rate_fee_structures_on_contract_id_unique_not_null"
  end
end
