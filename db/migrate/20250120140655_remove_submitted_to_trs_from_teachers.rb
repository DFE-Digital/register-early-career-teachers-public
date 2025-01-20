class RemoveSubmittedToTRSFromTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.remove :induction_start_date_submitted_to_trs_at, type: :datetime
      t.remove :induction_completion_submitted_to_trs_at, type: :datetime
    end
  end
end
