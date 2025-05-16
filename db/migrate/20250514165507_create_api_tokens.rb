class CreateAPITokens < ActiveRecord::Migration[8.0]
  def change
    create_enum :api_token_scopes, %w[lead_provider teacher_record_service]

    create_table :api_tokens do |t|
      t.references :lead_provider, foreign_key: true, null: false
      t.string :hashed_token, null: false
      t.datetime :last_used_at
      t.enum :scope, enum_type: "api_token_scopes", default: "lead_provider", null: false

      t.timestamps
    end

    add_check_constraint(
      :api_tokens,
      "(lead_provider_id IS NOT NULL AND scope = 'lead_provider') OR (lead_provider_id IS NULL AND scope <> 'lead_provider')"
    )

    add_index :api_tokens, :hashed_token, unique: true
    add_index :api_tokens, %i[hashed_token scope]
  end
end
