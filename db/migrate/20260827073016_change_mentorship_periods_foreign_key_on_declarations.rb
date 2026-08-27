class ChangeMentorshipPeriodsForeignKeyOnDeclarations < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :declarations, :mentorship_periods
    add_foreign_key :declarations, :mentorship_periods, on_delete: :nullify, validate: false
    validate_foreign_key :declarations, :mentorship_periods
  end

  def down
    remove_foreign_key :declarations, :mentorship_periods
    add_foreign_key :declarations, :mentorship_periods, validate: false
    validate_foreign_key :declarations, :mentorship_periods
  end
end
