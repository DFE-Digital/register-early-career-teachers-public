RSpec.describe "GET /api/hello/user", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }

  it "returns the appropriate body name" do
    get "/api/hello/user", headers: bearer_auth_headers(authorization:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("name" => "Golden Leaf Teaching School Hub")
  end
end
