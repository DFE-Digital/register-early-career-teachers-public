class CreateAPIOAuthClients < ActiveRecord::Migration[8.1]
  def change
    create_enum :oauth_grant_types, %w[authorization_code]

    create_table :api_oauth_clients do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret_digest, null: false
      t.string :redirect_uris, null: false, array: true, default: []
      t.enum :grant_types, enum_type: :oauth_grant_types, null: false, array: true, default: []

      t.timestamps
    end

    add_index :api_oauth_clients, :name, unique: true
    add_index :api_oauth_clients, :client_id, unique: true
  end
end
