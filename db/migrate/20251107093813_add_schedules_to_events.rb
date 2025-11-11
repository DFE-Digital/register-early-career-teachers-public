class AddSchedulesToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :schedule, null: true, foreign_key: true, index: false
  end
end
