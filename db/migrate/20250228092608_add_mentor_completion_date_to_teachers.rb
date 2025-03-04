class AddMentorCompletionDateToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :mentor_completion_date, :date
  end
end
