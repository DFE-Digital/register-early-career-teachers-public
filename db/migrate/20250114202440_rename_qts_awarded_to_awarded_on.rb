class RenameQtsAwardedToAwardedOn < ActiveRecord::Migration[8.0]
  def change
    rename_column :pending_induction_submissions, :trs_qts_awarded, :trs_qts_awarded_on
  end
end
