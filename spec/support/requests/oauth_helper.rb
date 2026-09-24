module OAuthHelper
  def basic_auth_headers(client:, secret: client.client_secret)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(client.client_id, secret) }
  end

  def bearer_auth_headers(authorization:, token: authorization.token)
    { "Authorization" => "Bearer #{token}" }
  end
end
