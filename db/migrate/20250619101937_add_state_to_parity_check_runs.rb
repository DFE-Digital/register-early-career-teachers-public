class AddStateToParityCheckRuns < ActiveRecord::Migration[8.0]
  def change
    create_enum :parity_check_run_states, %w[pending in_progress completed]

    change_table :parity_check_runs, bulk: true do |t|
      t.column :state, :parity_check_run_states, default: :pending, null: false
    end

    change_column_null :parity_check_runs, :started_at, true
  end
end
