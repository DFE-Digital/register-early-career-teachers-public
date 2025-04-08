class AddDfESignInOrganisationIdToAbs < ActiveRecord::Migration[7.2]
  def change
    add_column :appropriate_bodies, :dfe_sign_in_organisation_id, :uuid

    change_column :appropriate_bodies, :dfe_sign_in_organisation_id, :uuid, null: false

    add_index :appropriate_bodies, :dfe_sign_in_organisation_id, unique: true
  end
end
