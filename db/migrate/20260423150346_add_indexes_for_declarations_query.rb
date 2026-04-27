class AddIndexesForDeclarationsQuery < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Metadata teachers lead providers OR optimisation.
    add_index :metadata_teachers_lead_providers,
              %i[lead_provider_id teacher_id],
              name: "idx_metadata_lead_provider_ect_active",
              algorithm: :concurrently,
              where: "latest_ect_training_period_id IS NOT NULL"

    add_index :metadata_teachers_lead_providers,
              %i[lead_provider_id teacher_id],
              name: "idx_metadata_lead_provider_mentor_active",
              algorithm: :concurrently,
              where: "latest_mentor_training_period_id IS NOT NULL"
  end
end
