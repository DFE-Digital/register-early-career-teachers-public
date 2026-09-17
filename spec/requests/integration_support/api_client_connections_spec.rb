RSpec.describe "API client connections", type: :request do
  let(:connection_params) do
    {
      integration_support_api_client_connection: {
        response_type: "token",
        appropriate_body_period_id: "3",
        redirect_uri: "http://www.example.com/integration-support/api-client-connection",
        client_id: "test-client-id",
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

  it "redirects to the authorize endpoint with the authorization parameters" do
    post(integration_support_api_client_connection_path, params: connection_params)

    uri = URI.parse(response.location)
    expect(uri.path).to eq(oauth_authorization_path)
    expect(URI.decode_www_form(uri.query).to_h).to eq(
      "response_type" => "token",
      "client_id" => "test-client-id",
      "appropriate_body_period_id" => "3",
      "redirect_uri" => "http://www.example.com/integration-support/api-client-connection",
      "code_challenge" => "a-code-challenge",
      "code_challenge_method" => "S256",
      "state" => "state-123"
    )
  end

  it "responds with a bad request when no connection is in progress" do
    get(integration_support_api_client_connection_path, params: { code: "the-code" })

    expect(response).to have_http_status(:bad_request)
  end
end
