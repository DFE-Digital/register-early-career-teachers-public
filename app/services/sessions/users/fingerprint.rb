module Sessions
  module Users
    module Fingerprint
      def fingerprint(key = Rails.application.secret_key_base)
        OpenSSL::HMAC.hexdigest("SHA256", key, dfe_analytics_user_id.to_s)
      end
    end
  end
end
