class SetDefaultValueForTeachersAPIECTMentorTrainingRecordIds < ActiveRecord::Migration[8.1]
  change_table :teachers, bulk: true do |t|
    t.change_default :api_ect_training_record_id, from: nil, to: -> { "gen_random_uuid()" }
    t.change_default :api_mentor_training_record_id, from: nil, to: -> { "gen_random_uuid()" }
  end
end
