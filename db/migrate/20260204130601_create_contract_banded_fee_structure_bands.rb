class CreateContractBandedFeeStructureBands < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_banded_fee_structure_bands do |t|
      t.references :banded_fee_structure, foreign_key: { to_table: :contract_banded_fee_structures, on_delete: :cascade }, null: false
      t.integer :min_declarations, null: false, default: 1
      t.integer :max_declarations, null: false
      t.integer :fee_per_declaration, null: false
      t.decimal :output_fee_ratio, precision: 3, scale: 2, null: false
      t.decimal :service_fee_ratio, precision: 3, scale: 2, null: false

      t.timestamps
    end
  end
end
