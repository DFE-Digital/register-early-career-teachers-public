class CreateStatementItems < ActiveRecord::Migration[8.0]
  def change
    create_enum :statement_item_states, %w[eligible payable paid voided ineligible awaiting_clawback clawed_back]

    create_table :statement_items do |t|
      t.references :statement, null: false, foreign_key: true

      t.uuid :ecf_id, null: false, default: -> { "gen_random_uuid()" }
      t.enum :state, enum_type: "statement_item_states", default: "eligible", null: false

      t.timestamps
    end
  end
end
