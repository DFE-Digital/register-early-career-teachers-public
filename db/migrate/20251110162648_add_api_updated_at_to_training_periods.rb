class AddAPIUpdatedAtToTrainingPeriods < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :training_periods, :api_updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    add_index :training_periods, :api_updated_at, algorithm: :concurrently
  end
end
