class AddLastRefreshedTimestampToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :trs_data_last_refreshed_at, :timestamp
  end
end
