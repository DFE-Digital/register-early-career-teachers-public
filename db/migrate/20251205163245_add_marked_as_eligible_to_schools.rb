class AddMarkedAsEligibleToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :marked_as_eligible, :boolean, default: false, null: false
  end
end
