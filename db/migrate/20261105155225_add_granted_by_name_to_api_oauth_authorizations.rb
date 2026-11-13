class AddGrantedByNameToAPIOAuthAuthorizations < ActiveRecord::Migration[8.1]
  def change
    add_column :api_oauth_authorizations, :granted_by_name, :string
  end
end
