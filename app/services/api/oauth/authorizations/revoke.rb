module API::OAuth::Authorizations
  class Revoke
    attr_reader :client, :token

    def initialize(client:, token:)
      @client = client
      @token = token
    end

    def revoke!
      return if token.blank? || client.blank? || authorization.blank? || authorization.revoked?

      ActiveRecord::Base.transaction do
        authorization.revoke!
        Events::Record.record_api_oauth_authorization_revoked_event!(author:, authorization:)
        authorization
      end
    end

  private

    def authorization
      @authorization ||= client.authorizations.find_by(token_digest:)
    end

    def token_digest
      Digest::SHA256.hexdigest(token)
    end

    def author
      @author ||= Events::OAuthClientAuthor.new(client:)
    end
  end
end
