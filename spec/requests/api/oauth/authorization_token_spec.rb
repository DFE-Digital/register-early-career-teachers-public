RSpec.shared_examples "a request that generates an error response" do |http_status, message|
  it "returns an error" do
    post("/oauth/token", params:, headers: basic_auth)

    expect(response).to have_http_status(http_status)

    payload = JSON.parse(response.body)
    expect(payload["error"]).to eq message
  end

  it "does not confirm the Authorization" do
    expect {
      post("/oauth/token", params:, headers: basic_auth)
    }.to not_change(authorization, :code_exchanged_at).and not_change(authorization, :token_digest)
  end
end

RSpec.describe "API OAuth code for token exchange", type: :request do
  let(:params) do
    {
      grant_type:,
      code:,
      code_verifier:,
      redirect_uri:
    }
  end

  let(:client) { FactoryBot.create(:api_oauth_client, client_secret_digest:) }
  let(:client_secret) { "client-secret" }
  let(:client_secret_digest) { Digest::SHA256.hexdigest(client_secret) }
  let(:client_creds) { "#{client.client_id}:#{client_secret}" }

  let(:basic_auth) do
    {
      "Authorization" => "Basic #{Base64.strict_encode64(client_creds)}"
    }
  end

  let!(:authorization) { FactoryBot.create(:api_oauth_authorization, client:, code_challenge:) }
  let(:grant_type) { client.grant_types.first }
  let(:code) { "secret code" }
  let(:code_digest) { Digest::SHA256.hexdigest(code) }
  let(:code_expires_at) { 1.day.from_now }

  let(:challenge) { "code-challenge" }
  let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(challenge), padding: false) }

  let(:code_verifier) { challenge }
  let(:redirect_uri) { client.redirect_uris.first }

  describe "POST /oauth/token" do
    before do
      authorization.update!(code_digest:, code_expires_at:)
    end

    it "verifies the authorization record" do
      freeze_time do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:created)
        expect(authorization.reload.code_exchanged_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    it "returns the token payload" do
      post("/oauth/token", params:, headers: basic_auth)
      payload = JSON.parse(response.body)

      expect(Digest::SHA256.hexdigest(payload["access_token"])).to eq authorization.reload.token_digest
      expect(payload["expires_in"]).to eq 31_536_000
      expect(payload["token_type"]).to eq "Bearer"
    end

    context "when the authentication secret is incorrect" do
      let(:client_creds) { "#{client.client_id}:bananas" }

      it_behaves_like "a request that generates an error response", :unauthorized, "invalid_client"
    end

    context "when the authentication client_id is not found" do
      let(:client_creds) { "peanuts:bananas" }

      it_behaves_like "a request that generates an error response", :unauthorized, "invalid_client"
    end

    context "when no Authorization exists for the supplied code" do
      let(:code_digest) { Digest::SHA256.hexdigest("coconuts") }

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_grant"
    end

    context "when the Authorization code has expired" do
      let(:code_expires_at) { 1.hour.ago }

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_grant"
    end

    context "when the Authorization code has already been exchanged" do
      before do
        authorization.update!(code_exchanged_at: 1.hour.ago)
      end

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_grant"
    end

    context "when the code_challenge cannot be verified" do
      let(:params) do
        {
          grant_type:,
          code:,
          code_verifier: "pickled-onions",
          redirect_uri:
        }
      end

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_grant"
    end

    context "when the redirect_uri does not match the Authorization" do
      let(:redirect_uri) { "https://133t-hackorz.com" }

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_grant"
    end

    context "when the grant_type does not match the Client" do
      let(:grant_type) { "password" }

      it_behaves_like "a request that generates an error response", :bad_request, "unsupported_grant_type"
    end

    context "when the grant_type is missing" do
      let(:grant_type) { nil }

      it_behaves_like "a request that generates an error response", :bad_request, "invalid_request"
    end
  end
end
