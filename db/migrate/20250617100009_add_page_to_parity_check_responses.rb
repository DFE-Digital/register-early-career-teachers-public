class AddPageToParityCheckResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :parity_check_responses, :page, :integer, null: true
    add_index :parity_check_responses, %i[request_id page], unique: true
  end
end
