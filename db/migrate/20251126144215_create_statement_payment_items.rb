class CreateStatementPaymentItems < ActiveRecord::Migration[8.0]
  def change
    create_enum :statement_payment_item_statuses, %w[eligible payable paid voided ineligible]

    create_table :statement_payment_items do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :declaration, null: false, foreign_key: true, index: { unique: true }

      t.enum :status, enum_type: "statement_payment_item_statuses", default: "eligible", null: false
      t.uuid :ecf_id, index: { unique: true }

      t.timestamps
    end
  end
end
