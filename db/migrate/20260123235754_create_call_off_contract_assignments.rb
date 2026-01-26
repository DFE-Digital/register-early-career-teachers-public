class CreateCallOffContractAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :call_off_contract_assignments do |t|
      t.references :call_off_contract, null: false, foreign_key: true
      t.references :statement, null: false, foreign_key: true
      t.timestamps
    end
  end
end
