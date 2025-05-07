class RemoveRedundantColumnsFromSchoolPartnerships < ActiveRecord::Migration[8.0]
  def change
    change_table :school_partnerships do |t|
      t.remove_references :lead_provider, foreign_key: true
      t.remove_references :registration_period, foreign_key: true
      t.remove_references :delivery_partner, foreign_key: true
    end
  end
end
