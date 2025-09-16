class AddProhibitedFromTeachingToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :trs_prohibited_from_teaching, :boolean
  end
end
