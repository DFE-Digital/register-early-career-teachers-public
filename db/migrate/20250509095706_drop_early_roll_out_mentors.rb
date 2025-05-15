class DropEarlyRollOutMentors < ActiveRecord::Migration[8.0]
  def up
    drop_table :early_roll_out_mentors
  end

  def down
    create_table "early_roll_out_mentors", force: :cascade do |t|
      t.string "trn", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
