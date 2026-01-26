class CreateCallOffContractAssignments < ActiveRecord::Migration[8.0]
  def change
    create_enum :declaration_resolver_type, %w[all ect mentor], default: "all", null: false

    create_table :call_off_contract_assignments do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :call_off_contract_banded, null: true, foreign_key: true
      t.references :call_off_contract_flat_rate, null: true, foreign_key: true
      t.enum :declaration_resolver_type, null: false, enum_type: :declaration_resolver_type
      t.timestamps
    end
  end
end
