module API
  class BaseController < ActionController::API
    include API::TokenAuthenticatable

  private

    def api_token_scope
      APIToken.scopes[:lead_provider]
    end
  end
end
