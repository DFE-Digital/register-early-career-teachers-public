class AddAuthorToPendingInductionSubmissionBatch < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submission_batches, :author_id, :integer
    add_index :pending_induction_submission_batches, :author_id
  end
end
