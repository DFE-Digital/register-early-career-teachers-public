class AddUniqueIndexToInProgressParityCheckRuns < ActiveRecord::Migration[8.0]
  def change
    add_index :parity_check_runs, :state, unique: true, where: "state = 'in_progress'"
  end
end
