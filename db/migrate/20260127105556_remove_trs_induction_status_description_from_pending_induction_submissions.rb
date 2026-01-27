class RemoveTRSInductionStatusDescriptionFromPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :pending_induction_submissions, :trs_induction_status_description, :string
  end
end
