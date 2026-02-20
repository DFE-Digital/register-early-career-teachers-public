class AddOTPSchoolURNToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_school_urn, :string
  end
end
