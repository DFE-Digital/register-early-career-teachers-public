class MakeTeachersAPIECTMentorTrainingRecordIdsRequired < ActiveRecord::Migration[8.1]
  change_table :teachers, bulk: true do |t|
    t.change_null :api_ect_training_record_id, false
    t.change_null :api_mentor_training_record_id, false
  end
end
