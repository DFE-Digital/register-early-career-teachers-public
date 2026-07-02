module Sessions
  class UnlockOTPAccount
    attr_reader :author, :user

    def initialize(author:, user:)
      @author = author
      @user = user
    end

    def unlock
      ::User.transaction do
        user.assign_attributes(otp_failed_attempts: 0, otp_locked_at: nil)
        modifications = user.changes

        user.save!
        Events::Record.record_otp_account_unlocked_event!(author:, user:, modifications:) if modifications.any?
      end
    end
  end
end
