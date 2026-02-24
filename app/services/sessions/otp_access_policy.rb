module Sessions
  class OTPAccessPolicy
    INTERNAL_ADMIN_EMAIL_DOMAINS = %w[
      education.gov.uk
      digital.education.gov.uk
    ].freeze

    attr_reader :user, :otp_school_sign_in_enabled
    alias_method :otp_school_sign_in_enabled?, :otp_school_sign_in_enabled

    def initialize(user:, otp_school_sign_in_enabled:)
      @user = user
      @otp_school_sign_in_enabled = otp_school_sign_in_enabled
    end

    def allowed?
      return false unless user
      return true if internal_admin_email?

      otp_school_sign_in_enabled? && otp_marked_school_user?
    end

    def denied?
      !allowed?
    end

    def school_sign_in?
      otp_school_sign_in_enabled? && otp_marked_school_user?
    end

  private

    def otp_marked_school_user?
      user&.otp_school_urn.present?
    end

    def internal_admin_email?
      domain = user&.email.to_s.split("@", 2).last&.downcase
      INTERNAL_ADMIN_EMAIL_DOMAINS.include?(domain)
    end
  end
end
