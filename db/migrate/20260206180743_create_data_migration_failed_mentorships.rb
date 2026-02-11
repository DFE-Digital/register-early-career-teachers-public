class CreateDataMigrationFailedMentorships < ActiveRecord::Migration[8.0]
  def change
    create_table :data_migration_failed_mentorships do |t|
      t.uuid "ect_participant_profile_id"
      t.uuid "mentor_participant_profile_id"

      t.date "started_on"
      t.date "finished_on"

      t.uuid "ecf_start_induction_record_id"
      t.uuid "ecf_end_induction_record_id"

      t.text "failure_message"

      t.timestamps
    end
  end
end
