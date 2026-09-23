RSpec.describe "GET /api/hello/client", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client, name: "Vendor Ltd") }

  it "returns the client name" do
    get "/api/hello/client", headers: basic_auth_headers(client:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("name" => "Vendor Ltd")
  end

  it "rejects bad client credentials" do
    get "/api/hello/client", headers: basic_auth_headers(client:, secret: "wrong")
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("error" => "invalid_client")

    unknown_client = FactoryBot.build(:api_oauth_client)
    get "/api/hello/client", headers: basic_auth_headers(client: unknown_client)
    expect(response).to have_http_status(:unauthorized)

    get "/api/hello/client"
    expect(response).to have_http_status(:unauthorized)
  end
end
