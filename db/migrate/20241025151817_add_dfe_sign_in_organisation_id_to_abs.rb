class AddDfESignInOrganisationIdToAbs < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_column :appropriate_bodies, :dfe_sign_in_organisation_id, :uuid, null: false
    # rubocop:enable Rails/NotNullColumn
    add_index :appropriate_bodies, :dfe_sign_in_organisation_id, unique: true
  end
end
