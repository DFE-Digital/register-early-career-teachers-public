class IncreaseInductionStatusLimit < ActiveRecord::Migration[8.0]
  def up
    change_column :pending_induction_submissions, :trs_induction_status, :string, limit: 18
  end

  def down
    change_column :pending_induction_submissions, :trs_induction_status, :string, limit: 16
  end
end
