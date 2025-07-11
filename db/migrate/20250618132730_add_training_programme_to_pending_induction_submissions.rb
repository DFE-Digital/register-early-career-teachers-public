class AddTrainingProgrammeToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :training_programme, :training_programme
  end
end
