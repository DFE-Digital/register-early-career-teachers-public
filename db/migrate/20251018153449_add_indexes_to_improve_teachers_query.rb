class AddIndexesToImproveTeachersQuery < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :metadata_teachers_lead_providers,
              %i[lead_provider_id teacher_id],
              where: "latest_ect_training_period_id IS NOT NULL OR latest_mentor_training_period_id IS NOT NULL",
              algorithm: :concurrently

    add_index :teachers,
              :created_at,
              algorithm: :concurrently

    add_index :induction_periods,
              %i[teacher_id started_on],
              algorithm: :concurrently

    add_index :ect_at_school_periods,
              %i[teacher_id started_on],
              algorithm: :concurrently

    add_index :mentor_at_school_periods,
              %i[teacher_id started_on],
              algorithm: :concurrently
  end
end
