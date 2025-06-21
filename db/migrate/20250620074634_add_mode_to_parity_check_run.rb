class AddModeToParityCheckRun < ActiveRecord::Migration[8.0]
  def change
    create_enum :parity_check_run_modes, %w[concurrent sequential]

    change_table :parity_check_runs, bulk: true do |t|
      t.column :mode, :parity_check_run_modes, default: :concurrent, null: false
    end
  end
end
