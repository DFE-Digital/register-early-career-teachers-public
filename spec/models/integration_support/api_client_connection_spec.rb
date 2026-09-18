RSpec.describe IntegrationSupport::APIClientConnection, type: :model do
  let(:redirect_uri) { "http://localhost:3000/integration-support/api-client-connection/callback" }
  let(:base_url) { "http://localhost:3000" }

  it "assigns defaults" do
    connection = described_class.new(redirect_uri:)

    expect(connection).to have_attributes(
      redirect_uri:,
      response_type: API::OAuth::AuthorizationRequest::RESPONSE_TYPE,
      code_challenge_method: API::OAuth::Authorization.code_challenge_methods.values.first,
      grant_type: API::OAuth::Client::GRANT_TYPES.first,
      client_id: nil,
      client_secret: "clientSecret-integration-test"
    )
    expect(connection.state).to be_present
    expect(connection.code_verifier).not_to eq(described_class.new.code_verifier)
  end

  describe "#code_challenge" do
    it "hashes the code verifier" do
      expect(described_class.new(code_verifier: "the-verifier").code_challenge).to eq("sP6XQ2T7IHwj7eBkdcI9xyC8WxEik0RMQk0tVGDKZPI")
      expect(described_class.new(code_verifier: "the-verifier", code_challenge: "tampered").code_challenge).to eq("tampered")
    end
  end

  describe "#state_mismatch?" do
    it "detects a tampered state" do
      expect(described_class.new(state: "state-123", returned_state: "state-123")).not_to be_state_mismatch
      expect(described_class.new(state: "state-123", returned_state: "tampered")).to be_state_mismatch
      expect(described_class.new(state: "state-123")).not_to be_state_mismatch
    end
  end

  describe "#exchange_code_for_token" do
    subject(:exchange) { connection.exchange_code_for_token("#{base_url}/oauth/token") }

    let(:connection) do
      described_class.new(
        client_id: "test-client-id", client_secret: "test-client-secret",
        grant_type: "authorization_code", code: "the-code",
        code_verifier: "the-verifier", redirect_uri:
      )
    end

    before do
      stub_request(:post, "#{base_url}/oauth/token")
        .to_return(status: 201, headers: { content_type: "application/json" }, body: { access_token: "abc" }.to_json)
    end

    it "posts form-encoded grant parameters with HTTP basic client credentials" do
      expect(exchange.status).to eq(201)
      expect(exchange.body).to eq("access_token" => "abc")

      expect(
        a_request(:post, "#{base_url}/oauth/token").with(
          basic_auth: %w[test-client-id test-client-secret],
          headers: { content_type: "application/x-www-form-urlencoded" },
          body: {
            grant_type: "authorization_code",
            code: "the-code",
            code_verifier: "the-verifier",
            redirect_uri:
          }
        )
      ).to have_been_made.once
    end
  end
end
