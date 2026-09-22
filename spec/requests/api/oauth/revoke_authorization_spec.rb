RSpec.describe "API OAuth Authorization revoked by client", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client, client_secret_digest:) }
  let(:client_secret) { "client-secret" }
  let(:client_secret_digest) { Digest::SHA256.hexdigest(client_secret) }
  let(:client_creds) { "#{client.client_id}:#{client_secret}" }

  let(:basic_auth) do
    {
      "Authorization" => "Basic #{Base64.strict_encode64(client_creds)}"
    }
  end

  let!(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, client:) }
  let(:token) { authorization.token }

  let(:params) { { token:, } }

  let(:enable_apis_under_development) { true }

  before do
    allow(Rails.application.config)
      .to receive(:enable_apis_under_development) { enable_apis_under_development }
  end

  describe "POST /oauth/revoke" do
    it "revokes the authorization" do
      post("/oauth/revoke", params:, headers: basic_auth)

      expect(authorization.reload).to be_revoked
      expect(response).to have_http_status(:ok)
    end

    context "when the authentication secret is incorrect" do
      let(:client_creds) { "#{client.client_id}:bananas" }

      it "returns a error in json format" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:unauthorized)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_client"
      end
    end

    context "when client does not have an authorization matching the token" do
      let(:token) { "bananas" }

      it "returns 200 response" do
        post("/oauth/revoke", params:, headers: basic_auth)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the authorization is already revoked" do
      before do
        authorization.revoke!
      end

      it "returns 200 response" do
        post("/oauth/revoke", params:, headers: basic_auth)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when enable_apis_under_development is false" do
      let(:enable_apis_under_development) { false }

      it "returns 404 response" do
        post("/oauth/revoke", params:, headers: basic_auth)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
