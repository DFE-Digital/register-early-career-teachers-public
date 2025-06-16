class AddSchoolIdToSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :school_partnerships, :school, null: false, foreign_key: true, index: false
    # rubocop:enable Rails/NotNullColumn

    add_index :school_partnerships, %i[school_id lead_provider_delivery_partnership_id], unique: true
  end
end
