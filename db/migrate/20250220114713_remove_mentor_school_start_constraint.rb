class RemoveMentorSchoolStartConstraint < ActiveRecord::Migration[8.0]
  def change
    remove_index :mentor_at_school_periods, column: %i[teacher_id started_on], name: "index_mentor_at_school_periods_on_teacher_id_started_on", unique: true
  end
end
