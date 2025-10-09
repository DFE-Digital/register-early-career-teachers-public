class RemoveTeacherIdStartedOnIndexOnECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    remove_index :ect_at_school_periods, column: %i[teacher_id started_on]
    add_index :ect_at_school_periods, %i[teacher_id started_on], unique: true, where: "status = 'active'"
  end
end
