class RemoveAPIUpdatedAtFromSchools < ActiveRecord::Migration[8.0]
  def change
    remove_column :schools, :api_updated_at, :datetime
  end
end
