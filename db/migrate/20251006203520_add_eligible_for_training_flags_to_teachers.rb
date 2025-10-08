class AddEligibleForTrainingFlagsToTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.datetime :ect_first_became_eligible_for_training_at, null: true
      t.datetime :mentor_first_became_eligible_for_training_at, null: true
    end
  end
end
