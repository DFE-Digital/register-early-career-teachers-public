class CreateSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    create_table :school_partnerships do |t|
      t.references :lead_provider_delivery_partnership, null: true, foreign_key: true
      t.references :school, null: false, foreign_key: true

      t.timestamps
    end
  end
end
