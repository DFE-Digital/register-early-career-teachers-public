class MakeParityCheckRunStartedAtRequired < ActiveRecord::Migration[8.0]
  def change
    change_column_null :parity_check_runs, :started_at, false
  end
end
