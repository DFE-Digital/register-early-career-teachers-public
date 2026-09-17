RSpec.describe "API client connections", type: :request do
  let(:redirect_uri) { "http://www.example.com/integration-support/api-client-connection" }
  let(:connection_params) do
    {
      integration_support_api_client_connection: {
        response_type: "token",
        appropriate_body_period_id: "3",
        redirect_uri:,
        client_id: "test-client-id",
        client_secret: "test-client-secret",
        code_verifier: "the-verifier",
        code_challenge: "a-code-challenge",
        code_challenge_method: "S256",
        state: "state-123"
      }
    }
  end

  before { allow(Rails.application.config).to receive(:enable_api_test_client).and_return(true) }

  it "is only available when the test client is enabled" do
    get(new_integration_support_api_client_connection_path)
    expect(response).to have_http_status(:ok)

    allow(Rails.application.config).to receive(:enable_api_test_client).and_return(false)
    get(new_integration_support_api_client_connection_path)
    expect(response).to have_http_status(:not_found)
  end

  describe "GET /integration-support/api-client-connection/new" do
    it "renders" do
      appropriate_body_period = FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub")
      client = FactoryBot.create(:api_oauth_client, name: "Vendor A")

      get(new_integration_support_api_client_connection_path)

      page = Capybara.string(response.body)
      expect(response).to have_http_status(:ok)
      expect(page).to have_select("Appropriate body period ID", with_options: [appropriate_body_period.name])
      expect(page).to have_select("Client ID", with_options: [client.name, "Unknown client", "Blank client"])
      expect(page).to have_field("Redirect URI", with: redirect_uri)
      expect(page).to have_button("Start authorization request")
    end
  end

  describe "POST /integration-support/api-client-connection" do
    it "stores the connection and redirects to the authorize endpoint" do
      post(integration_support_api_client_connection_path, params: connection_params)

      expect(response).to redirect_to(
        oauth_authorization_path(
          response_type: "token",
          client_id: "test-client-id",
          appropriate_body_period_id: 3,
          redirect_uri:,
          code_challenge: "a-code-challenge",
          code_challenge_method: "S256",
          state: "state-123"
        )
      )
      expect(session[:api_client_connection]).to include("client_id" => "test-client-id", "state" => "state-123")
    end
  end

  describe "GET /integration-support/api-client-connection" do
    it "renders with the returned code" do
      post(integration_support_api_client_connection_path, params: connection_params)
      get(integration_support_api_client_connection_path, params: { code: "the-code", state: "state-123" })

      page = Capybara.string(response.body)
      expect(response).to have_http_status(:ok)
      expect(page).to have_css(".app-summary-card--green", text: "the-code")
      expect(page).to have_no_text("does not match the state sent with the authorization request")
      expect(page).to have_field("Code", with: "the-code", exact: true)
      expect(page).to have_field("Code verifier (PKCE)", with: "the-verifier")
      expect(page).to have_button("Exchange code for token")
    end

    it "returns a bad request when there is no connection in progress" do
      get(integration_support_api_client_connection_path, params: { code: "the-code" })
      expect(response).to have_http_status(:bad_request)

      patch(integration_support_api_client_connection_path, params: connection_params)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /integration-support/api-client-connection" do
    let(:token_url) { "http://www.example.com/oauth/token" }
    let(:update_params) do
      {
        integration_support_api_client_connection: {
          client_id: "test-client-id",
          client_secret: "test-client-secret",
          grant_type: "authorization_code",
          code: "the-code",
          code_verifier: "the-verifier",
          redirect_uri:
        }
      }
    end

    before { post(integration_support_api_client_connection_path, params: connection_params) }

    it "exchanges the code for a token and shows the response" do
      stub_request(:post, token_url)
        .to_return(status: 201, headers: { content_type: "application/json" }, body: { access_token: "abc" }.to_json)

      patch(integration_support_api_client_connection_path, params: update_params)

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_css(".app-summary-card--green pre", text: '"access_token": "abc"')
      expect(
        a_request(:post, token_url).with(
          basic_auth: %w[test-client-id test-client-secret],
          body: { grant_type: "authorization_code", code: "the-code", code_verifier: "the-verifier", redirect_uri: }
        )
      ).to have_been_made.once
    end

    it "shows the error when the token endpoint cannot be reached" do
      stub_request(:post, token_url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      patch(integration_support_api_client_connection_path, params: update_params)

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_css(".app-summary-card--red", text: "Connection refused")
    end
  end
end
