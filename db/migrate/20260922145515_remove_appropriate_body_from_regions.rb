class RemoveAppropriateBodyFromRegions < ActiveRecord::Migration[8.1]
  def change
    remove_column :regions, :appropriate_body_id, :bigint
  end
end
