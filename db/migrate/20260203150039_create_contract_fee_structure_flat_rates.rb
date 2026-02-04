class CreateContractFeeStructureFlatRates < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_fee_structure_flat_rates do |t|
      t.integer :recruitment_target, null: false
      t.decimal :fee_per_declaration, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
