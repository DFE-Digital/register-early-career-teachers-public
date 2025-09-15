class AddRequestDetailsToParityCheckResponses < ActiveRecord::Migration[8.0]
  def change
    change_table :parity_check_responses, bulk: true do |t|
      t.string :ecf_request_uri
      t.string :rect_request_uri
      t.jsonb :request_body
    end
  end
end
