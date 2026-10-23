RSpec.describe "GET /api/induction/v1/appropriate-bodies", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client) }

  it "returns the active appropriate bodies ordered by name" do
    golden_leaf = FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub")
    bright_futures = FactoryBot.create(:appropriate_body_period, name: "Bright Futures Teaching School Hub")
    FactoryBot.create(:appropriate_body_period, :inactive, name: "Oldshire Local Authority")

    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([
      { "uuid" => bright_futures.external_uuid, "name" => "Bright Futures Teaching School Hub" },
      { "uuid" => golden_leaf.external_uuid, "name" => "Golden Leaf Teaching School Hub" },
    ])
  end

  it "rejects bad client credentials" do
    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client:, secret: "wrong")
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("error" => "invalid_client")

    unknown_client = FactoryBot.build(:api_oauth_client)
    get "/api/induction/v1/appropriate-bodies", headers: basic_auth_headers(client: unknown_client)
    expect(response).to have_http_status(:unauthorized)

    get "/api/induction/v1/appropriate-bodies"
    expect(response).to have_http_status(:unauthorized)
  end
end
