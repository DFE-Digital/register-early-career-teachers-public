class CreateEarlyRollOutMentors < ActiveRecord::Migration[8.0]
  def change
    create_table :early_roll_out_mentors do |t|
      t.string :trn, null: false
      t.timestamps
    end
  end
end
