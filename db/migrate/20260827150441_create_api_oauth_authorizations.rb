class CreateAPIOAuthAuthorizations < ActiveRecord::Migration[8.1]
  def change
    create_enum :oauth_code_challenge_methods, %w[S256]

    create_table :api_oauth_authorizations do |t|
      t.references :client, null: false, foreign_key: { to_table: :api_oauth_clients }
      t.references :appropriate_body_period, null: false, foreign_key: true
      t.string :redirect_uri, null: false
      t.string :code_digest, null: false
      t.string :code_challenge, null: false
      t.enum :code_challenge_method, enum_type: :oauth_code_challenge_methods, null: false
      t.datetime :code_expires_at, null: false
      t.datetime :code_exchanged_at
      t.string :token_digest
      t.datetime :token_expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_oauth_authorizations, :code_digest, unique: true
    add_index :api_oauth_authorizations, :token_digest, unique: true
  end
end
