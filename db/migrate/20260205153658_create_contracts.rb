class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.enum "contract_type", null: false, enum_type: "contract_types"
      t.references :flat_rate_fee_structure, foreign_key: { to_table: :contract_flat_rate_fee_structures }, index: { unique: true }
      t.references :banded_fee_structure, foreign_key: { to_table: :contract_banded_fee_structures }, index: { unique: true }

      t.timestamps
    end
  end
end
