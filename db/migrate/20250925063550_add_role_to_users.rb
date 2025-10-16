class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :enum, enum_type: :dfe_role_type, null: false, default: "admin"
  end
end
