class RemoveTeacherIdStartedOnIndexOnECTAtSchoolPeriods < ActiveRecord::Migration[8.0]
  def change
    remove_index :ect_at_school_periods, column: %i[teacher_id started_on]
  end
end
