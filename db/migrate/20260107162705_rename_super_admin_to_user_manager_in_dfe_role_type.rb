class RenameSuperAdminToUserManagerInDfERoleType < ActiveRecord::Migration[8.0]
  def change
    rename_enum_value :dfe_role_type, from: "super_admin", to: "user_manager"
  end
end
