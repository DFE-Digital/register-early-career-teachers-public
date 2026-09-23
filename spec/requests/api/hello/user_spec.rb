RSpec.describe "GET /api/hello/user", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }

  it "returns the appropriate body name" do
    get "/api/hello/user", headers: bearer_auth_headers(authorization:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("name" => "Golden Leaf Teaching School Hub")
  end

  it "rejects when token missing" do
    get "/api/hello/user"

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to eq("Bearer")
    expect(response.body).to be_empty
  end

  it "rejects an unknown token" do
    get "/api/hello/user", headers: bearer_auth_headers(authorization:, token: "unknown")

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to eq(%(Bearer error="invalid_token"))
    expect(response.parsed_body).to eq("error" => "invalid_token")
  end

  it "rejects an expired or revoked token" do
    FactoryBot.create(:api_oauth_authorization, :with_expired_token, token: "expired-token")
    get "/api/hello/user", headers: { "Authorization" => "Bearer expired-token" }
    expect(response).to have_http_status(:unauthorized)

    revoked = FactoryBot.create(:api_oauth_authorization, :with_token, :revoked)
    get "/api/hello/user", headers: bearer_auth_headers(authorization: revoked)
    expect(response).to have_http_status(:unauthorized)
  end
end
