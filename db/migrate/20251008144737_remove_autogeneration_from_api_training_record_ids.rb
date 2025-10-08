class RemoveAutogenerationFromAPITrainingRecordIds < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.change_default :api_ect_training_record_id, from: -> { "gen_random_uuid()" }, to: nil
      t.change_default :api_mentor_training_record_id, from: -> { "gen_random_uuid()" }, to: nil

      t.change_null :api_ect_training_record_id, true
      t.change_null :api_mentor_training_record_id, true
    end
  end
end
