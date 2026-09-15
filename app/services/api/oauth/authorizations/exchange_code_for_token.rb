module API::OAuth::Authorizations
  class ExchangeCodeForToken
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :authorization_token_request

    def call
      ActiveRecord::Base.transaction do
        authorization = authorization_token_request.authorization

        if authorization_token_request.valid?
          authorization.exchange_code_for_token!(code_verifier: authorization_token_request.code_verifier)
          author = Events::OAuthClientAuthor.new(client: authorization.client)
          Events::Record.record_api_oauth_authorization_code_exchanged(author:, authorization:)
        end

        authorization
      end
    end
  end
end
