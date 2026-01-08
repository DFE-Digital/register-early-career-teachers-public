class RenameSuperAdminToUserManagerInDfERoleType < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      ALTER TYPE dfe_role_type
      RENAME VALUE 'super_admin' TO 'user_manager';
    SQL
  end

  def down
    execute <<~SQL
      ALTER TYPE dfe_role_type
      RENAME VALUE 'user_manager' TO 'super_admin';
    SQL
  end
end
