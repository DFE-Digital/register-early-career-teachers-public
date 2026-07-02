class AddOTPLockingToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.integer :otp_failed_attempts, default: 0, null: false
      t.datetime :otp_locked_at
    end
  end
end
