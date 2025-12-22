class AddFailConfirmationSentOnToPendingInductionSubmission < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :fail_confirmation_sent_on, :date
  end
end
