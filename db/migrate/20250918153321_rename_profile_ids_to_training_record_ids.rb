class RenameProfileIdsToTrainingRecordIds < ActiveRecord::Migration[8.0]
  def change
    rename_column :teachers, :api_ect_profile_id, :api_ect_training_record_id
    rename_column :teachers, :api_mentor_profile_id, :api_mentor_training_record_id
  end
end
