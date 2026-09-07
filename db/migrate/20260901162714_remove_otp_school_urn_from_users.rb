class RemoveOTPSchoolURNFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :otp_school_urn, :integer
  end
end
