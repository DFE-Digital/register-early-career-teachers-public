class AddStatementAdjustmentToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :statement_adjustment, index: true, null: true, foreign_key: { on_delete: :nullify }
  end
end
