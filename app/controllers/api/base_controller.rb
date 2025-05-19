module API
  class BaseController < ActionController::API
    include API::TokenAuthenticatable

  private

    # Option 1: Using scopes
    def api_token_scope
      APIToken.scopes[:lead_provider]
    end

    # Option 2: Using polymorphic associations
    def api_tokenable_type
      "LeadProvider"
    end
  end
end
