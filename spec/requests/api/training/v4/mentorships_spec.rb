RSpec.describe "GET /api/training/v4/cohorts/:year/mentorships", type: :request do
  it "returns an empty OK response for an existing lead provider API token" do
    api_token = FactoryBot.create(:api_token)

    get "/api/training/v4/cohorts/2026/mentorships", headers: api_headers(token: api_token.token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to be_empty
  end
end
