class AddAPIColumnsToTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.uuid :api_user_id, null: false, default: -> { "gen_random_uuid()" }
      t.uuid :api_ect_profile_id, null: false, default: -> { "gen_random_uuid()" }
      t.uuid :api_mentor_profile_id, null: false, default: -> { "gen_random_uuid()" }
      t.index :api_user_id, unique: true
      t.index :api_ect_profile_id, unique: true
      t.index :api_mentor_profile_id, unique: true
    end
  end
end
