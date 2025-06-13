class ChangeRequestsToUseEndpoints < ActiveRecord::Migration[8.0]
  change_table :parity_check_requests, bulk: true do |t|
    t.remove :path
    t.remove :method
    t.references :endpoint, foreign_key: { to_table: :parity_check_endpoints }
  end
end
