class CreateInvalidRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :invalid_records do |t|
      t.string  :table_name, null: false
      t.bigint  :record_id, null: false
      t.text    :error_messages, null: false
      t.timestamps
    end

    add_index :invalid_records, %i[table_name record_id], unique: true
  end
end
