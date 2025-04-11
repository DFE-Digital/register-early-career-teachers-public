class ChangeLimitOfTRSInductionStatusField < ActiveRecord::Migration[8.0]
  def up
    change_column :teachers, :trs_induction_status, :string, limit: 18
  end

  def down
    change_column :teachers, :login, :trs_induction_status, limit: 16
  end
end
