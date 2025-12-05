class AddEligibleToGIASSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :gias_schools, :eligible, :boolean, default: false, null: false
  end
end
