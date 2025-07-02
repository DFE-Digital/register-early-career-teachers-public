class AddPendingInductionSubmissionBatchIndexToEvent < ActiveRecord::Migration[8.0]
  def change
    add_index :events, %i[pending_induction_submission_batch_id]
  end
end
