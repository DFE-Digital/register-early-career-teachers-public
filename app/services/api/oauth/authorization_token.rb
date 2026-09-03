module API
  module OAuth
    class AuthorizationToken
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :client
      attribute :grant_type
      attribute :code
      attribute :code_verifier
      attribute :redirect_uri

      validates :client, presence: { message: "Enter a client" }
      validates :grant_type, presence: { message: "invalid_request" }
      validates :grant_type, inclusion: { in: -> { it.client.grant_types }, message: "unsupported_grant_type" }
      validates :code, presence: { message: "invalid_grant" }
      validates :code_verifier, presence: { message: "invalid_grant" }
      validates :redirect_uri, presence: { message: "invalid_grant" }

      validate :code_matches
      validate :code_verifier_is_valid
      validate :redirect_uri_matches_authorization

      def code_matches
        return if errors.any?

        errors.add(:code, "invalid_grant") if authorization_request.blank?
      end

      def code_verifier_is_valid
        return if errors.any?

        errors.add(:code_verifier, "invalid_grant") unless code_challenge_verified?
      end

      def redirect_uri_matches
        return if errors.any?

        ActiveSupport::SecurityUtils.secure_compare(redirect_uri, authorization_request.redirect_uri)
      end

      def code_digest
        @code_digest ||= Digest::SHA256.hexdigest(code)
      end

      def code_challenge_verified?
        return false unless authorization_request&.code_challenge_method == "S256"

        expected_code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)

        ActiveSupport::SecurityUtils.secure_compare(expected_code_challenge, authorization_request.code_challenge)
      end

      def authorization_request
        @authorization_request ||= client&.authorizations&.find_by(code_digest:)
      end
    end
  end
end
