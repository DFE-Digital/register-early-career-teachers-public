class CreateStatementClawbackItems < ActiveRecord::Migration[8.0]
  def change
    create_enum :statement_clawback_item_statuses, %w[awaiting_clawback clawed_back]

    create_table :statement_clawback_items do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :declaration, null: false, foreign_key: true, index: { unique: true }

      t.enum :status, enum_type: "statement_clawback_item_statuses", default: "awaiting_clawback", null: false
      t.uuid :ecf_id, index: { unique: true }

      t.timestamps
    end
  end
end
