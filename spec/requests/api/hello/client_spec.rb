RSpec.describe "GET /api/hello/client", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client, name: "Vendor Ltd") }

  it "returns the client name" do
    get "/api/hello/client", headers: basic_auth_headers(client:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("name" => "Vendor Ltd")
  end
end
