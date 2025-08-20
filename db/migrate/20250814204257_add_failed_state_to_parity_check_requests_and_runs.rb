class AddFailedStateToParityCheckRequestsAndRuns < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :parity_check_request_states, "failed"
    add_enum_value :parity_check_run_states, "failed"
  end
end
