class AddIndexToPendingInductionSubmissionsTRN < ActiveRecord::Migration[8.0]
  def change
    add_index :pending_induction_submissions, :trn
  end
end
