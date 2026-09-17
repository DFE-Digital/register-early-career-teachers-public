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
        raise(CodeNotExchangeableError, "Code cannot be exchanged") unless code_exchangable?
        raise(CodeNotExchangeableError, "Code verifier is invalid") unless code_challenge_verified?(code_verifier:)

        authorization.assign_token
        authorization.update!(code_exchanged_at: Time.zone.now)

        author = Events::OAuthClientAuthor.new(client: authorization.client)
        Events::Record.record_api_oauth_authorization_code_exchanged(author:, authorization:)

        authorization
      end
    end
  end
end
