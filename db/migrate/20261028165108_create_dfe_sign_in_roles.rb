class CreateDfESignInRoles < ActiveRecord::Migration[8.1]
  def change
    create_enum :dfe_sign_in_role_code, %w[school_user appropriate_body_user]

    create_table :dfe_sign_in_roles do |t|
      t.enum :code, enum_type: :dfe_sign_in_role_code, null: false
      t.string :dfe_sign_in_role_id, null: false

      t.index :code, unique: true
      t.index :dfe_sign_in_role_id, unique: true

      t.timestamps
    end
  end
end
