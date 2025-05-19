class CreateNewAPITokens < ActiveRecord::Migration[8.0]
  def change
    create_table :new_api_tokens do |t|
      t.references :tokenable, polymorphic: true, index: true

      t.string :hashed_token, null: false
      t.string :description
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :new_api_tokens, :hashed_token, unique: true
  end
end
