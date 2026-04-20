class AddCompositeIndexesForTransferUpdates < ActiveRecord::Migration[8.0]
  def up
    add_index :training_periods,
              %i[api_transfer_updated_at ect_at_school_period_id],
              name: "idx_training_periods_transfer_updated_ect",
              where: "ect_at_school_period_id IS NOT NULL"

    add_index :training_periods,
              %i[api_transfer_updated_at mentor_at_school_period_id],
              name: "idx_training_periods_transfer_updated_mentor",
              where: "mentor_at_school_period_id IS NOT NULL"

    add_index :lead_provider_delivery_partnerships,
              [:active_lead_provider_id],
              name: "idx_lpdps_active_lead_provider"
  end

  def down
    remove_index :training_periods, name: "idx_training_periods_transfer_updated_ect"
    remove_index :training_periods, name: "idx_training_periods_transfer_updated_mentor"
    remove_index :lead_provider_delivery_partnerships, name: "idx_lpdps_active_lead_provider"
  end
end
