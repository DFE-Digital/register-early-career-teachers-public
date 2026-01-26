class CreateCallOffContractBanded < ActiveRecord::Migration[8.0]
  def change
    create_table :call_off_contract_banded do |t|
      t.integer :uplift_target, null: false
      t.decimal :uplift_fee_per_declaration, null: false
      t.decimal :monthly_service_fee, null: false
      t.decimal :setup_fee, null: false
      t.timestamps
    end
  end
end
