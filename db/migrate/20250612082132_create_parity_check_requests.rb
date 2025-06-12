class CreateParityCheckRequests < ActiveRecord::Migration[8.0]
  def change
    create_enum :request_method_types, %w[get post put]

    create_table :parity_check_requests do |t|
      t.references :run, foreign_key: { to_table: :parity_check_runs }, null: false, index: true
      t.references :lead_provider, foreign_key: true, null: false, index: true

      t.string :path, null: false
      t.enum :method, enum_type: :request_method_types, null: false

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
