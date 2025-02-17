class AllowNullDfESignInOrganisationIds < ActiveRecord::Migration[8.0]
  def up
    change_column :appropriate_bodies, :dfe_sign_in_organisation_id, :uuid, null: true
  end

  def down
    change_column :appropriate_bodies, :dfe_sign_in_organisation_id, :uuid, null: false
  end
end
