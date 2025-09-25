class DropDfEUserRoles < ActiveRecord::Migration[8.0]
  def up
    drop_table :dfe_roles
  end

  def down
    create_table "dfe_roles", force: :cascade do |t|
      t.enum "role_type", default: "admin", null: false, enum_type: "dfe_role_type"
      t.integer "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index %w[user_id], name: "index_dfe_roles_on_user_id"
    end
  end
end
