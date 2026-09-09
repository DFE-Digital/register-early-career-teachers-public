class RemoveTeacherChangesFk < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :teacher_id_changes, :teachers, column: :api_from_teacher_id
    remove_foreign_key :teacher_id_changes, :teachers, column: :api_to_teacher_id
  end
end
