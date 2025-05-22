class CreateAPITokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :lead_provider, index: true

      t.string :token, null: false
      t.string :description, null: false
      t.datetime :last_used_at

      t.timestamps

      t.index :token, unique: true
    end
  end
end
