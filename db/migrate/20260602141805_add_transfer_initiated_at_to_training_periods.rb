class AddTransferInitiatedAtToTrainingPeriods < ActiveRecord::Migration[8.1]
  def change
    add_column :training_periods, :transfer_initiated_at, :datetime
  end
end
