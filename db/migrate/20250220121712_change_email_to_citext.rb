class ChangeEmailToCitext < ActiveRecord::Migration[8.0]
  def up
    enable_extension "citext"

    change_column :users, :email, :citext
    change_column :mentor_at_school_periods, :email, :citext
    change_column :ect_at_school_periods, :email, :citext
    change_column :events, :author_email, :citext
    change_column :pending_induction_submissions, :trs_email_address, :citext
  end

  def down
    change_column :users, :email, :string
    change_column :mentor_at_school_periods, :email, :string
    change_column :ect_at_school_periods, :email, :string
    change_column :events, :author_email, :string
    change_column :pending_induction_submissions, :trs_email_address, :string
  end
end
