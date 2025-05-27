module APIHelper
  def authenticated_api_get(path, token: nil)
    get path, headers: api_headers(token:)
  end

  def authenticated_api_post(path, token: nil)
    post path, headers: api_headers(token:)
  end

  def authenticated_api_put(path, token: nil)
    put path, headers: api_headers(token:)
  end

  def api_headers(token: nil)
    {
      Authorization: "Bearer #{token || generate_api_token.token}"
    }
  end

  def generate_api_token
    lead_provider = FactoryBot.create(:lead_provider)
    API::TokenManager.create_lead_provider_api_token!(lead_provider:)
  end
end
