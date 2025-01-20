class AddUniqueConstraintToEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :ect_at_school_periods, :email, unique: true, where: "email IS NOT NULL", name: "unique_email_on_ect_at_school_periods"
    add_index :mentor_at_school_periods, :email, unique: true, where: "email IS NOT NULL", name: "unique_email_on_mentor_at_school_periods"
  end
end
