class AddEligibleForTrainingFlagsToTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.datetime :first_became_eligible_for_ect_training_at, null: true
      t.datetime :first_became_eligible_for_mentor_training_at, null: true
    end
  end
end
