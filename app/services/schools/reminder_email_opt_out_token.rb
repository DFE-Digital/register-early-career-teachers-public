module Schools
  # Generates the HMAC token used in the reminder email opt-out link
  class ReminderEmailOptOutToken
    class MissingSecretError < StandardError
      def initialize = super("SCHOOL_REMINDER_EMAIL_OPT_OUT_TOKEN_SECRET is not configured")
    end

    PURPOSE = "school-reminder-email-opt-out"

    class << self
      def generate_for(school_id:)   = new(school_id:).generate
      def valid?(school_id:, token:) = new(school_id:).valid?(token)

      def token_sql(school_id_sql:)
        message = "'#{PURPOSE}:' || (#{school_id_sql})::text"
        quoted_secret = ActiveRecord::Base.connection.quote(secret)

        "encode(hmac(#{message}, #{quoted_secret}, 'sha256'), 'hex')"
      end

    private

      def secret
        Rails.application.config.school_reminder_email_opt_out_token_secret.presence ||
          raise(MissingSecretError)
      end
    end

    def initialize(school_id:)
      @school_id = school_id.to_s
    end

    def generate
      OpenSSL::HMAC.hexdigest("SHA256", self.class.send(:secret), "#{PURPOSE}:#{@school_id}")
    end

    def valid?(token)
      return false if token.blank?

      ActiveSupport::SecurityUtils.secure_compare(token, generate)
    end
  end
end
