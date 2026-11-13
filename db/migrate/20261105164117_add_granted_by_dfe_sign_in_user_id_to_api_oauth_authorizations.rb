class AddGrantedByDfESignInUserIdToAPIOAuthAuthorizations < ActiveRecord::Migration[8.1]
  def change
    add_column :api_oauth_authorizations, :granted_by_dfe_sign_in_user_id, :string
  end
end
