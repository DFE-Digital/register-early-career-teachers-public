module Sessions
  class OneTimePassword
    MAX_FAILED_ATTEMPTS = 10

    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def generate_and_send_code
      code = generate

      Rails.logger.debug(Colourize.text("\n===>>> OTP code for #{user.email} is: [#{code}] <<<===\n", :yellow))

      OTPMailer.with(recipient_email: user.email,
                     recipient_name: user.name,
                     code:).otp_code_email.deliver_later
    end

    def generate
      generate_otp_secret!
      totp.now
    end

    def verify(code:)
      user.with_lock do
        return false if user.otp_locked_at.present?

        params = {
          drift_behind: 10.minutes.in_seconds, # give a 10 minute window to use the OTP code
          after: user.otp_verified_at,         # prevents re-use of OTP code within the window
        }.compact

        tm = totp.verify(code, **params)

        if tm.blank?
          record_failed_attempt_and_lock_if_needed!
          return false
        end

        user.update!(otp_verified_at: Time.zone.at(tm), otp_failed_attempts: 0)
      end
    end

  private

    def totp
      ROTP::TOTP.new(user.otp_secret, issuer: "ECF2")
    end

    def generate_otp_secret!
      user.update!(otp_secret: ROTP::Base32.random(16))
    end

    def record_failed_attempt_and_lock_if_needed!
      attributes = { otp_failed_attempts: user.otp_failed_attempts + 1 }.tap do |attrs|
        attrs[:otp_locked_at] = Time.zone.now if attrs[:otp_failed_attempts] >= MAX_FAILED_ATTEMPTS
      end

      user.assign_attributes(attributes)
      modifications = user.changes

      user.save!
      Events::Record.record_otp_account_locked_event!(user:, modifications:) if attributes.key?(:otp_locked_at)
    end
  end
end
