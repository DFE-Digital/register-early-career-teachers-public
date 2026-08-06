class AddProductTeamToDfERoleType < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :dfe_role_type, "product_team"
  end
end
