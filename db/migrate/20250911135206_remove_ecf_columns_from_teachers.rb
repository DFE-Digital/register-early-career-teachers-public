class RemoveECFColumnsFromTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.remove :ecf_user_id, type: :uuid
      t.remove :ecf_ect_profile_id, type: :uuid
      t.remove :ecf_mentor_profile_id, type: :uuid
    end
  end
end
