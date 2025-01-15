class AddTRSFieldsToTeacher < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.rename 'first_name', 'trs_first_name'
      t.rename 'last_name', 'trs_last_name'
      t.rename 'qts_awarded_on', 'trs_qts_awarded_on'

      t.string 'trs_qts_status_description'
      t.string 'trs_induction_status', limit: 16
      t.string 'trs_initial_teacher_training_provider_name'
      t.date 'trs_initial_teacher_training_end_date'
    end
  end
end
