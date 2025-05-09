class AddEarlyRollOutMentorsFlagToTeacher < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :early_roll_out_mentor, :boolean, default: false, null: false
  end
end
