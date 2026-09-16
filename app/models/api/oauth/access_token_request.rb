module API
  module OAuth
    class AccessTokenRequest
      include ActiveModel::Model
      include ActiveModel::Attributes

      class RequestNotExchangeableError < StandardError; end

      attribute :authorization
      attribute :grant_type
      attribute :code_verifier
      attribute :redirect_uri

      validates :authorization, presence: { message: "invalid_grant" }
      validate :grant_type_is_supported_by_client
      validate :code_can_be_exchanged
      validate :code_verifier_is_valid
      validate :redirect_uri_matches_authorization

      delegate :client, to: :authorization
      delegate :code_exchangable?, to: :authorization, prefix: true, allow_nil: true

      def exchange_code_for_token!
        raise RequestNotExchangeableError, "Request is not exchangeable" unless valid?

        Authorizations::ExchangeCodeForToken.new(authorization:, code_verifier:).call
      end

      def access_token
        return nil unless authorization.token

        {
          access_token: authorization.token,
          expires_in: authorization.seconds_to_token_expiration,
          token_type: "Bearer",
        }
      end

      def error_message
        return nil unless errors.any?

        {
          error: errors.first.message
        }
      end

    private

      def code_can_be_exchanged
        return if errors.any?

        errors.add(:code, "invalid_grant") unless authorization_code_exchangable?
      end

      def code_verifier_is_valid
        return if errors.any?

        errors.add(:code_verifier, "invalid_grant") unless code_verifier.present? &&
          authorization.code_challenge_verified?(code_verifier:)
      end

      def grant_type_is_supported_by_client
        return if errors.any?

        errors.add(:grant_type, "invalid_request") and return if grant_type.blank?

        errors.add(:grant_type, "unsupported_grant_type") unless grant_type.in?(client.grant_types)
      end

      def redirect_uri_matches_authorization
        return if errors.any?

        errors.add(:redirect_uri, "invalid_grant") unless redirect_uri.present? &&
          ActiveSupport::SecurityUtils.secure_compare(redirect_uri, authorization.redirect_uri)
      end
    end
  end
end
