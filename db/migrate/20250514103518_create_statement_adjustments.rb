class CreateStatementAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_adjustments do |t|
      t.references :statement, null: false, foreign_key: true

      t.uuid :ecf_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :payment_type, null: false
      t.decimal :amount, default: 0.0, null: false

      t.timestamps
    end
  end
end
