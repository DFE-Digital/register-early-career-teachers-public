class CreateCallOffContractFlatRate < ActiveRecord::Migration[8.0]
  def change
    create_table :call_off_contract_flat_rates do |t|
      t.integer :recruitment_target, null: false
      t.decimal :fee_per_declaration, null: false
      t.timestamps
    end
  end
end
