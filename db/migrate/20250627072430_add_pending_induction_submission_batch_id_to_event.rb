class AddPendingInductionSubmissionBatchIdToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :pending_induction_submission_batch_id, :bigint
  end
end
