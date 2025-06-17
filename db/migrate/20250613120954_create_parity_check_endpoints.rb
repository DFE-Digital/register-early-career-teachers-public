class CreateParityCheckEndpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :parity_check_endpoints do |t|
      t.string :path, null: false
      t.enum :method, enum_type: :request_method_types, null: false
      t.jsonb :options, default: {}, null: false

      t.timestamps
    end
  end
end
