class AddStateToParityCheckRequests < ActiveRecord::Migration[8.0]
  def change
    create_enum :parity_check_request_states, %w[pending queued in_progress completed]

    change_table :parity_check_requests, bulk: true do |t|
      t.column :state, :parity_check_request_states, default: :pending, null: false
    end
  end
end
