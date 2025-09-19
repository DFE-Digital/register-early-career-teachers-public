class BackfillTeachersAPIIds < ActiveRecord::Migration[8.0]
  def up
    Teacher.find_each do |teacher|
      updates = {}
      updates[:api_user_id] = teacher.ecf_user_id if teacher.ecf_user_id.present?
      updates[:api_ect_profile_id] = teacher.ecf_ect_profile_id if teacher.ecf_ect_profile_id.present?
      updates[:api_mentor_profile_id] = teacher.ecf_mentor_profile_id if teacher.ecf_mentor_profile_id.present?

      teacher.update!(updates) if updates.any?
    end
  end

  def down = nil
end
