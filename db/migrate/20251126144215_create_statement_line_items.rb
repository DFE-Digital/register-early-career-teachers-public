class CreateStatementLineItems < ActiveRecord::Migration[8.0]
  def change
    create_enum :statement_line_item_statuses, %w[eligible payable paid voided ineligible awaiting_clawback clawed_back]

    create_table :statement_line_items do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :declaration, null: false, foreign_key: true

      t.enum :status, enum_type: "statement_line_item_statuses", default: "eligible", null: false
      t.uuid :ecf_id, index: { unique: true }

      t.timestamps
    end

    add_index :statement_line_items, %i[declaration_id status], unique: true
  end
end
