class CreateContractBandedFeeStructures < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_banded_fee_structures do |t|
      t.integer :recruitment_target, null: false
      t.decimal :uplift_fee_per_declaration, precision: 12, scale: 2, null: false
      t.decimal :monthly_service_fee, precision: 12, scale: 2, null: false
      t.decimal :setup_fee, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
