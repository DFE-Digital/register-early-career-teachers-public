class BackfillSchoolsAPIId < ActiveRecord::Migration[8.0]
  def up
    School.eager_load(:gias_school).find_each do |school|
      school.update!(api_id: school.gias_school.api_id)
    end
  end

  def down = nil
end
