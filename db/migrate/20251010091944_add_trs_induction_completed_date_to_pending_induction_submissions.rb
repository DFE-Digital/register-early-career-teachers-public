class AddTRSInductionCompletedDateToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :trs_induction_completed_date, :date
  end
end
