class RemoveEstablishmentIdAndMakePartsNullable < ActiveRecord::Migration[7.2]
  def up
    remove_column :appropriate_bodies, :establishment_id, :string
    change_column :appropriate_bodies, :establishment_number, :integer, null: true
    change_column :appropriate_bodies, :local_authority_code, :integer, null: true
  end
end
