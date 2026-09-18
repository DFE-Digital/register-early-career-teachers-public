module API::OAuth::Authorizations
  class ExchangeCodeForToken
    include ActiveModel::Model
    include ActiveModel::Attributes

    class CodeNotExchangeableError < StandardError; end

    attribute :authorization
    attribute :code_verifier

    delegate :code_exchangable?, :code_challenge_verified?, to: :authorization

    def call
      ActiveRecord::Base.transaction do
        validate_code!
        revoke_active_predecessor!
        exchange_code!
        record_event!

        authorization
      end
    end

  private

    def validate_code!
      raise(CodeNotExchangeableError, "Code cannot be exchanged") unless code_exchangable?
      raise(CodeNotExchangeableError, "Code verifier is invalid") unless code_challenge_verified?(code_verifier:)
    end

    def revoke_active_predecessor!
      predecessor = authorization.active_predecessor
      return if predecessor.blank?

      API::OAuth::Authorizations::RevocationRequest.new(authorization: predecessor).revoke!
    end

    def exchange_code!
      authorization.assign_token
      authorization.update!(code_exchanged_at: Time.zone.now)
    end

    def record_event!
      author = Events::OAuthClientAuthor.new(client: authorization.client)
      Events::Record.record_api_oauth_authorization_code_exchanged_event!(author:, authorization:)
    end
  end
end
