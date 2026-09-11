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

      validates :client, presence: { message: "invalid_client" }

      validate :grant_type_is_supported_by_client
      validate :code_can_be_exchanged
      validate :code_verifier_is_valid
      validate :redirect_uri_matches_authorization

      delegate :token, to: :authorization

      def create
        return unless valid?

        ActiveRecord::Base.transaction do
          authorization.exchange_code_for_token!(code_verifier:)

          Events::Record.record_api_oauth_authorization_code_exchanged(author:, authorization:)

          return [token, authorization.seconds_to_token_expiration]
        end
      end

    private

      def code_can_be_exchanged
        return if errors.any?

        errors.add(:code, "invalid_grant") unless code.present? && authorization_code_exchangable?
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

      def authorization_code_exchangable?
        authorization.present? && authorization.code_exchangable?
      end

      def authorization
        @authorization ||= client&.authorization_for!(code:)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def author
        @author ||= Events::AppropriateBodyAuthor.new(appropriate_body_period: authorization.appropriate_body_period)
      end
    end
  end
end
