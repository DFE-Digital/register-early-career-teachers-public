class FixContractReferenceIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :contracts, :flat_rate_fee_structure_id
    remove_index :contracts, :banded_fee_structure_id

    # Allow multiple contracts with NULL references, but enforce uniqueness when the reference is present.
    add_index :contracts, :flat_rate_fee_structure_id, unique: true, where: "flat_rate_fee_structure_id IS NOT NULL"
    add_index :contracts, :banded_fee_structure_id, unique: true, where: "banded_fee_structure_id IS NOT NULL"
  end
end
