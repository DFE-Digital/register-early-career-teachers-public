class AddPerformanceIndexesToSchoolsAndGIASSchools < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :schools, :api_updated_at, algorithm: :concurrently
  end
end
