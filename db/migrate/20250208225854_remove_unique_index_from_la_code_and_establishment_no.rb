class RemoveUniqueIndexFromLaCodeAndEstablishmentNo < ActiveRecord::Migration[8.0]
  def change
    remove_index :appropriate_bodies, column: %w[local_authority_code establishment_number], name: "idx_on_local_authority_code_establishment_number_039c79cd09", unique: true
  end
end
