class AddTRSInductionDatesToTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.date :trs_induction_start_date
      t.date :trs_induction_completed_date
    end
  end
end
