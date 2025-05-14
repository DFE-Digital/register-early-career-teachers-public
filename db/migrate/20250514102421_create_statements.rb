class CreateStatements < ActiveRecord::Migration[8.0]
  def change
    create_enum :statement_states, %w[open payable paid]

    create_table :statements do |t|
      t.references :lead_provider_active_period, null: false, foreign_key: true

      t.uuid :ecf_id, null: false, default: -> { "gen_random_uuid()" }
      t.integer :month, null: false
      t.integer :year, null: false
      t.date :deadline_date, null: false
      t.date :payment_date, null: false
      t.datetime :marked_as_paid_at
      t.boolean :output_fee, default: true, null: false
      t.enum :state, enum_type: "statement_states", default: "open", null: false

      t.timestamps
    end
  end
end
