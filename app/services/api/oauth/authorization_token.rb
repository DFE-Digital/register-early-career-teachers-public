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
      validates :code, presence: { message: "invalid_grant" }
      validates :code_verifier, presence: { message: "invalid_grant" }
      validates :redirect_uri, presence: { message: "invalid_grant" }

      validate :grant_type_is_supported_by_client
      validate :code_can_be_exchanged
      validate :code_verifier_is_valid
      validate :redirect_uri_matches_authorization

      attr_reader :token

      def create
        return unless valid?

        ActiveRecord::Base.transaction do
          @token = authorization_request.assign_token
          authorization_request.update!(code_exchanged_at: Time.zone.now)

          Events::Record.record_api_oauth_authorization_verified(author:, authorization: authorization_request)

          return [token, authorization_request.token_expires_at]
        end
      end

      def code_can_be_exchanged
        return if errors.any?

        errors.add(:code, "invalid_grant") unless authorization_confirmable?
      end

      def code_verifier_is_valid
        return if errors.any?

        errors.add(:code_verifier, "invalid_grant") unless code_challenge_verified?
      end

      def grant_type_is_supported_by_client
        return if errors.any?

        errors.add(:grant_type, "unsupported_grant_type") unless grant_type.in? client.grant_types
      end

      def redirect_uri_matches_authorization
        return if errors.any?

        errors.add(:redirect_uri, "invalid_grant") unless ActiveSupport::SecurityUtils.secure_compare(redirect_uri, authorization_request.redirect_uri)
      end

      def code_challenge_verified?
        return false unless authorization_request&.s256?

        presented_code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)

        ActiveSupport::SecurityUtils.secure_compare(authorization_request.code_challenge, presented_code_challenge)
      end

      def authorization_confirmable?
        authorization_request.present? && !authorization_request.code_expired? && authorization_request.code_exchanged_at.blank?
      end

      def authorization_request
        @authorization_request ||= client&.authorizations&.find_by(code_digest:)
      end

      def code_digest
        @code_digest ||= Digest::SHA256.hexdigest(code)
      end

      def author
        @author ||= Events::ClientAuthor.new(client:)
      end
    end
  end
end
