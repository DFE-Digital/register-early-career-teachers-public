class AddWrittenFailConfirmationOnToPendingInductionSubmission < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :written_fail_confirmation_on, :date
  end
end
