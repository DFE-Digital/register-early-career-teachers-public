module API::OAuth::Authorizations
  class Revoke
    attr_reader :authorization

    def initialize(authorization:)
      @authorization = authorization
    end

    def revoke!
      return if authorization.blank? || authorization.revoked?

      ActiveRecord::Base.transaction do
        authorization.revoke!
        Events::Record.record_api_oauth_authorization_revoked_event!(author:, authorization:)
        authorization
      end
    end

  private

    def author
      @author ||= Events::OAuthClientAuthor.new(client: authorization.client)
    end
  end
end
