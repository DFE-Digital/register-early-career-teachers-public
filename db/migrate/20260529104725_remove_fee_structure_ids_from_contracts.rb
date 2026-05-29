class RemoveFeeStructureIdsFromContracts < ActiveRecord::Migration[8.1]
  def change
    remove_reference :contracts, :flat_rate_fee_structure, foreign_key: { to_table: :contract_flat_rate_fee_structures }, index: { unique: true }
    remove_reference :contracts, :banded_fee_structure, foreign_key: { to_table: :contract_banded_fee_structures }, index: { unique: true }
  end
end
