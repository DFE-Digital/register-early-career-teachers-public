class RenameLegacyMigrationFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :ect_at_school_periods, :legacy_start_id, :ecf_start_induction_record_id
    rename_column :ect_at_school_periods, :legacy_end_id, :ecf_end_induction_record_id

    rename_column :mentor_at_school_periods, :legacy_start_id, :ecf_start_induction_record_id
    rename_column :mentor_at_school_periods, :legacy_end_id, :ecf_end_induction_record_id

    rename_column :mentorship_periods, :legacy_start_id, :ecf_start_induction_record_id
    rename_column :mentorship_periods, :legacy_end_id, :ecf_end_induction_record_id

    rename_column :teachers, :legacy_id, :ecf_user_id
    rename_column :teachers, :legacy_ect_id, :ecf_ect_profile_id
    rename_column :teachers, :legacy_mentor_id, :ecf_mentor_profile_id

    rename_column :training_periods, :legacy_start_id, :ecf_start_induction_record_id
    rename_column :training_periods, :legacy_end_id, :ecf_end_induction_record_id
  end
end
