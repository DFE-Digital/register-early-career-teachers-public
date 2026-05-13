class BackfillTeachersAPIIds < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE teachers
      SET
        api_user_id = COALESCE(ecf_user_id, api_user_id),
        api_ect_profile_id = COALESCE(ecf_ect_profile_id, api_ect_profile_id),
        api_mentor_profile_id = COALESCE(ecf_mentor_profile_id, api_mentor_profile_id),
        updated_at = CURRENT_TIMESTAMP
      WHERE ecf_user_id IS NOT NULL
        OR ecf_ect_profile_id IS NOT NULL
        OR ecf_mentor_profile_id IS NOT NULL
    SQL
  end

  def down = nil
end
