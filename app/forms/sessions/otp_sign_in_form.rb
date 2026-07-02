module Sessions
  class OTPSignInForm
    include ActiveModel::Model
    include ActiveRecord::AttributeAssignment
    include ActiveModel::Serialization

    attr_accessor :email, :code

    validates :email, presence: { message: "Enter your email address" }, notify_email: true
    validate :code_is_verified, on: :verify

    def attributes
      { email:, code: }
    end

    def generate_and_email_code_to_user!
      otp.generate_and_send_code
    end

    def user
      @user ||= ::User.find_by(email:)
    end

  private

    def code_is_verified
      errors.delete(:email) # prevent leaking info when the email does not match a known User

      errors.add(:code, "Enter the 6-digit code from the email") and return unless /\A\d{6}\z/.match?(code)

      if user&.otp_locked_at.present?
        errors.add(:code, "Your account is locked, please contact support")
        return
      end

      return if user && otp.verify(code:)

      if user&.otp_locked_at.present?
        errors.add(:code, "Your account is locked, please contact support")
      else
        errors.add(:code, "The code entered is invalid")
      end
    end

    def otp
      @otp ||= OneTimePassword.new(user:)
    end
  end
end
