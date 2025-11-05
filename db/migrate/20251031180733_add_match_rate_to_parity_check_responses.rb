class AddMatchRateToParityCheckResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :parity_check_responses, :match_rate, :integer, null: false, default: 0
  end
end
