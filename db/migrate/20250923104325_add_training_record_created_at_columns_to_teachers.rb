class AddTrainingRecordCreatedAtColumnsToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :api_ect_training_record_created_at, :datetime
    add_column :teachers, :api_mentor_training_record_created_at, :datetime
  end
end
