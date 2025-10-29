class AddIndexesToImproveTeachersQuery < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Targets join on lead_provider_metadata to filter teachers by lead provider.
    add_index :metadata_teachers_lead_providers,
              %i[lead_provider_id teacher_id],
              where: "latest_ect_training_period_id IS NOT NULL OR latest_mentor_training_period_id IS NOT NULL",
              algorithm: :concurrently

    # Targets default sort order.
    add_index :teachers,
              :created_at,
              algorithm: :concurrently
  end
end
