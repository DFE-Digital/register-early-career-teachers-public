class AddUniqueIndexToSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    add_index :school_partnerships, %i[school_id lead_provider_delivery_partnership_id], unique: true
  end
end
