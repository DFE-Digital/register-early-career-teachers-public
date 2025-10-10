class AddTRSDoBToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :trs_date_of_birth, :date
  end
end
