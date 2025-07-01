class AddAPIIdToGIASSchool < ActiveRecord::Migration[8.0]
  def change
    add_column :gias_schools, :api_id, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :gias_schools, :api_id, unique: true
  end
end
