module API::OAuth::Authorizations
  class ExchangeCodeForToken
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :authorization
    attribute :code_verifier

    def call
      ActiveRecord::Base.transaction do
        authorization.exchange_code_for_token!(code_verifier:)
        author = Events::OAuthClientAuthor.new(client: authorization.client)
        Events::Record.record_api_oauth_authorization_code_exchanged(author:, authorization:)

        authorization
      end
    end
  end
end
