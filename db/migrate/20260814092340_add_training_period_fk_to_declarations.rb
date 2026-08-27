class AddTrainingPeriodFkToDeclarations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_foreign_key :declarations, :training_periods, on_delete: :restrict, validate: false
    validate_foreign_key :declarations, :training_periods
  end

  def down
    remove_foreign_key :declarations, :training_periods
  end
end
