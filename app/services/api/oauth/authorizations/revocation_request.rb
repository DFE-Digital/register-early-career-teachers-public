module API::OAuth::Authorizations
  class RevocationRequest
    attr_reader :authorization

    def initialize(authorization:)
      @authorization = authorization
    end

    def revoke!
      return unless authorization&.revokable?

      ActiveRecord::Base.transaction do
        authorization.revoke!
        Events::Record.record_api_oauth_access_token_revoked_event!(author:, authorization:)
        authorization
      end
    end

  private

    def author
      @author ||= Events::OAuthClientAuthor.new(client: authorization.client)
    end
  end
end
