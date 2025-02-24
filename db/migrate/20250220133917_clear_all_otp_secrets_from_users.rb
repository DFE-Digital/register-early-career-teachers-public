class ClearAllOTPSecretsFromUsers < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE users SET otp_secret = NULL WHERE otp_secret IS NOT NULL")
  end

  def down = nil
end
