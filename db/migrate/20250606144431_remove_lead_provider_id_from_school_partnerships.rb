class RemoveLeadProviderIdFromSchoolPartnerships < ActiveRecord::Migration[8.0]
  def up
    remove_column :school_partnerships, :lead_provider_id
  end

  def down
    add_column :school_partnerships, :lead_provider_id, :bigint, null: false
  end
end
