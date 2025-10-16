class CreateTeacherIdChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_id_changes do |t|
      t.references :teacher, null: false, foreign_key: true
      t.references :api_from_teacher, null: false, type: :uuid, foreign_key: {to_table: :teachers, primary_key: :api_user_id}
      t.references :api_to_teacher, null: false, type: :uuid, foreign_key: {to_table: :teachers, primary_key: :api_user_id}
      t.uuid :ecf_id, index: {unique: true}

      t.timestamps
    end
  end
end
