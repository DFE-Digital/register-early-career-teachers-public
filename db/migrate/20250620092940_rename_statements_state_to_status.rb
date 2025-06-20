class RenameStatementsStateToStatus < ActiveRecord::Migration[8.0]
  def change
    rename_enum :statement_states, :statement_statuses
    rename_column :statements, :state, :status
  end
end
