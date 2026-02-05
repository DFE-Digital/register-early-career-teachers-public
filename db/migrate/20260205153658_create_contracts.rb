class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.enum "contract_type", null: false, enum_type: "contract_types"
      t.references :contract_flat_rate_fee_structure, foreign_key: true, index: true
      t.references :contract_banded_fee_structure, foreign_key: true, index: true

      t.timestamps
    end

    add_index :contracts, %i[contract_type contract_flat_rate_fee_structure_id], unique: true
    add_index :contracts, %i[contract_type contract_banded_fee_structure_id], unique: true
  end
end
