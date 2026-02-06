class AddPerformanceIndexesToSchoolsAndGIASSchools < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :schools, :api_updated_at, algorithm: :concurrently
    add_index :schools, :marked_as_eligible, algorithm: :concurrently
    add_index :gias_schools, :eligible, algorithm: :concurrently
  end
end
