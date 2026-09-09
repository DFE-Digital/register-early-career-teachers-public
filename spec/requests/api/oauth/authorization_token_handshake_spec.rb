RSpec.describe "API OAuth Token Handshake", type: :request do
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
      allow(RecordEventJob).to receive(:perform_later).and_return(true)
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

    it "generates an Event" do
      freeze_time do
        post("/oauth/token", params:, headers: basic_auth)

        expect(RecordEventJob).to have_received(:perform_later).with(
          author_name: client.name,
          author_type: "api_oauth_client",
          event_type: :api_oauth_authorization_verified,
          happened_at: authorization.reload.code_exchanged_at,
          heading: "Authorization verified by client '#{client.name}' for '#{authorization.appropriate_body_name}'"
        )
      end
    end

    context "when the authentication secret is incorrect" do
      let(:client_creds) { "#{client.client_id}:bananas" }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:unauthorized)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_client"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the authentication client_id is not found" do
      let(:client_creds) { "peanuts:bananas" }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:unauthorized)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_client"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when no Authorization exists for the supplied code" do
      let(:code_digest) { Digest::SHA256.hexdigest("coconuts") }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_grant"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the Authorization code has expired" do
      let(:code_expires_at) { 1.hour.ago }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_grant"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the Authorization code has already been exchanged" do
      before do
        authorization.update!(code_exchanged_at: 1.hour.ago)
      end

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_grant"
      end

      it "does not change the Authorization" do
        expect {
          post("/oauth/token", params:, headers: basic_auth)
        }.not_to change(authorization, :updated_at)
      end
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

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_grant"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the redirect_uri does not match the Authorization" do
      let(:redirect_uri) { "https://133t-hackorz.com" }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_grant"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the grant_type does not match the Client" do
      let(:grant_type) { "password" }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "unsupported_grant_type"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end

    context "when the grant_type is missing" do
      let(:grant_type) { nil }

      it "returns an error" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(response).to have_http_status(:bad_request)

        payload = JSON.parse(response.body)
        expect(payload["error"]).to eq "invalid_request"
      end

      it "does not confirm the Authorization" do
        post("/oauth/token", params:, headers: basic_auth)

        expect(authorization.reload.code_exchanged_at).to be_blank
        expect(authorization.token_digest).to be_blank
      end
    end
  end
end
