class CreateDataMigrationFailedCombinations < ActiveRecord::Migration[8.0]
  def change
    create_table :data_migration_failed_combinations do |t|
      t.string "trn"
      t.uuid "profile_id"
      t.string "profile_type"

      t.uuid "induction_record_id"
      t.string "training_programme"

      t.string "school_urn"
      t.integer "cohort_year"
      t.string "lead_provider_name"
      t.string "delivery_partner_name"

      t.datetime "start_date"
      t.datetime "end_date"

      t.string "induction_status"
      t.string "training_status"

      t.uuid "mentor_profile_id"

      t.uuid "schedule_id"
      t.string "schedule_identifier"
      t.string "schedule_name"
      t.integer "schedule_cohort_year"

      t.string "preferred_identity_email"

      t.text "failure_message"
      t.timestamps
    end
  end
end
