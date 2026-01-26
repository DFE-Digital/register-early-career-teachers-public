class CreateCallOffContractBandedBands < ActiveRecord::Migration[8.0]
  def change
    create_table :call_off_contract_banded_bands do |t|
      t.references :banded_contract, null: false, foreign_key: { to_table: :call_off_contract_banded }
      t.integer :min_declarations, null: false
      t.integer :max_declarations, null: false
      t.decimal :fee_per_declaration, null: false
      t.decimal :output_fee_ratio, null: false
      t.decimal :service_fee_ratio, null: false
      t.timestamps
    end
  end
end
