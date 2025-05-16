class AddDataToPendingInductionSubmissionBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submission_batches, :data, :jsonb
  end
end
