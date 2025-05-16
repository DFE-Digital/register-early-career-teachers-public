class AddFilenameToPendingInductionSubmissionBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submission_batches, :filename, :string
  end
end
