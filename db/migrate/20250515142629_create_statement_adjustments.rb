class CreateStatementAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_adjustments do |t|
      t.references :statement, null: false, foreign_key: true

      # Only needed for migrating data from ECF; can be removed later.
      t.uuid :api_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :payment_type, null: false
      t.decimal :amount, null: false

      t.timestamps
    end
  end
end
