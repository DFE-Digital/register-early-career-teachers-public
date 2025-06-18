class AddTrainingProgrammeToInductionPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :induction_periods, :training_programme, :training_programme
  end
end
