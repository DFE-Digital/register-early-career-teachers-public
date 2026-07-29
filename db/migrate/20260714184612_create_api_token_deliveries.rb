class CreateAPITokenDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :api_token_deliveries do |t|
      t.references :api_token, null: false, foreign_key: true, index: true
      t.string :token, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end
    add_index :api_token_deliveries, :expires_at
  end
end
