class BackfillEmptyTeachersTrainingRecordIds < ActiveRecord::Migration[8.1]
  def up
    Teacher.where(api_ect_training_record_id: nil).find_each do |teacher|
      teacher.update!(api_ect_training_record_id: SecureRandom.uuid)
    end

    Teacher.where(api_mentor_training_record_id: nil).find_each do |teacher|
      teacher.update!(api_mentor_training_record_id: SecureRandom.uuid)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
