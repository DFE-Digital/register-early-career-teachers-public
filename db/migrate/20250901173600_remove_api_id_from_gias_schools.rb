class RemoveAPIIdFromGIASSchools < ActiveRecord::Migration[8.0]
  def up
    remove_column :gias_schools, :api_id
  end

  def down
    add_column :gias_schools, :api_id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :gias_schools, :api_id, unique: true

    GIAS::School.eager_load(:school).find_each do |gias_school|
      gias_school.update!(api_id: gias_school.school.api_id)
    end
  end
end
