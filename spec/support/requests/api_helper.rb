module APIHelper
  def authenticated_api_get(path, token: nil, headers: {}, params: {})
    get path, headers: api_headers(token:).merge(headers), params:
  end

  def authenticated_api_post(path, token: nil, headers: {}, params: {})
    post path, headers: api_headers(token:).merge(headers), params:
  end

  def authenticated_api_put(path, token: nil, headers: {}, params: {})
    put path, headers: api_headers(token:).merge(headers), params:
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

  def parsed_response
    Oj.load(response.body).deep_symbolize_keys
  end

  def parsed_response_data
    parsed_response[:data]
  end

  def parsed_response_errors
    parsed_response[:errors]
  end
end
