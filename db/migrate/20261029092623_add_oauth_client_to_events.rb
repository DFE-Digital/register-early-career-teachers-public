class AddOAuthClientToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :oauth_client, index: true, null: true, foreign_key: { to_table: :api_oauth_clients, on_delete: :nullify }
  end
end
