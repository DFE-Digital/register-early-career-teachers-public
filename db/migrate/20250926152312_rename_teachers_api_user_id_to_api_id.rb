class RenameTeachersAPIUserIdToAPIId < ActiveRecord::Migration[8.0]
  def change
    rename_column :teachers, :api_user_id, :api_id
  end
end
