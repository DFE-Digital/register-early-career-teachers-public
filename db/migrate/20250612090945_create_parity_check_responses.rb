class CreateParityCheckResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :parity_check_responses do |t|
      t.references :request, foreign_key: { to_table: :parity_check_requests }, null: false, index: true

      t.integer :ecf_status_code, null: false
      t.integer :rect_status_code, null: false

      t.string :ecf_body
      t.string :rect_body

      t.integer :ecf_time_ms, null: false
      t.integer :rect_time_ms, null: false

      t.timestamps
    end
  end
end
