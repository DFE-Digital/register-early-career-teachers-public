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

        revoke_active_authorizations_matching!(authorization:)

        authorization.assign_token
        authorization.update!(code_exchanged_at: Time.zone.now)

        author = Events::OAuthClientAuthor.new(client: authorization.client)
        Events::Record.record_api_oauth_authorization_code_exchanged_event!(author:, authorization:)

        authorization
      end
    end

  private

    def revoke_active_authorizations_matching!(authorization:)
      authorization.client
        .authorizations
        .active
        .where(appropriate_body_period: authorization.appropriate_body_period,
               redirect_uri: authorization.redirect_uri)
        .where.not(id: authorization.id)
        .find_each do |authorization_to_be_revoked|
          API::OAuth::Authorizations::RevocationRequest.new(authorization: authorization_to_be_revoked).revoke!
        end
    end
  end
end
