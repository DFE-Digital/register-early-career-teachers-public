class RemoveDeliveryPartnerIdFromSchoolPartnerships < ActiveRecord::Migration[8.0]
  def up
    remove_column :school_partnerships, :delivery_partner_id
  end

  def down
    add_column :school_partnerships, :delivery_partner_id, :bigint, null: false
  end
end
