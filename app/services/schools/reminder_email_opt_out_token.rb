module Schools
  # Generates the HMAC token used in the reminder email opt-out link
  #
  # Equivalent SQL for use in Blazer:
  #
  #   SELECT
  #     id,
  #     '<host>/school/opt-out-of-reminder-emails/new?school_id=' || id ||
  #       '&token=' || encode(hmac('school-reminder-email-opt-out:' || id::text,
  #                                '<secret>', 'sha256'), 'hex')
  #       AS reminder_email_opt_out_url
  #   FROM schools
  #   WHERE opted_out_of_reminder_emails_until IS NULL
  #      OR opted_out_of_reminder_emails_until < CURRENT_DATE;
  #
  # `<secret>` is SCHOOL_REMINDER_EMAIL_OPT_OUT_TOKEN_SECRET in ENV
  class ReminderEmailOptOutToken
    class MissingSecretError < StandardError; end

    PURPOSE = "school-reminder-email-opt-out"

    def self.generate_for(school_id:)   = new(school_id:).generate
    def self.valid?(school_id:, token:) = new(school_id:).valid?(token)

    def initialize(school_id:)
      @school_id = school_id.to_s
    end

    def generate
      OpenSSL::HMAC.hexdigest("SHA256", secret, "#{PURPOSE}:#{@school_id}")
    end

    def valid?(token)
      return false if token.blank?

      ActiveSupport::SecurityUtils.secure_compare(token, generate)
    end

  private

    def secret
      Rails.application.config.school_reminder_email_opt_out_token_secret.presence ||
        raise(MissingSecretError, "SCHOOL_REMINDER_EMAIL_OPT_OUT_TOKEN_SECRET is not configured")
    end
  end
end
