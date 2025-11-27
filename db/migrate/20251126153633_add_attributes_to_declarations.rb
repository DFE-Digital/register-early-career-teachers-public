class AddAttributesToDeclarations < ActiveRecord::Migration[8.0]
  def change
    create_enum :declaration_statuses, %w[submitted eligible payable paid voided ineligible awaiting_clawback clawed_back]
    create_enum :evidence_types, %w[training-event-attended self-study-material-completed materials-engaged-with-offline 75-percent-engagement-met 75-percent-engagement-met-reduced-induction one-term-induction other]
    create_enum :ineligibility_reasons, %w[duplicate]

    # There is no data in the declarations table yet, so we can safely remove
    # the string column and add a new one with enum values.
    remove_column :declarations, :declaration_type, :string

    change_table :declarations, bulk: true do |t|
      t.references :voided_by_user, null: true, foreign_key: { to_table: :users }
      t.references :mentor_teacher, null: true, foreign_key: { to_table: :teachers }

      t.datetime :voided_at
      t.uuid :api_id, default: -> { "gen_random_uuid()" }, null: false
      t.datetime :date, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.enum :evidence_type, enum_type: "evidence_types"
      t.enum :status, enum_type: "declaration_statuses", default: "submitted", null: false
      t.enum :ineligibility_reason, enum_type: "ineligibility_reasons"
      t.enum :declaration_type, enum_type: "declaration_types", null: false, default: "started"
      t.boolean :sparsity_uplift, default: false, null: false
      t.boolean :pupil_premium_uplift, default: false, null: false
    end

    add_index :declarations, :api_id, unique: true
  end
end
