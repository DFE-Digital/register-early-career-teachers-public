RSpec.describe "API OAuth authorizations", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:redirect_uri) { client.redirect_uris.first }

  let(:params) do
    {
      response_type: "code",
      client_id: client.client_id,
      appropriate_body_period_id: appropriate_body_period.id,
      redirect_uri:,
      code_challenge: "hR8Nc3vLpQ2xY7bF",
      code_challenge_method: "S256",
      state: "xyz",
    }
  end

  describe "GET /oauth/authorize" do
    context "when not signed in" do
      it "redirects to the root page, keeping the whole authorize URL to return to" do
        get("/oauth/authorize", params:)

        expect(response).to redirect_to(root_url)
        expect(session[:requested_path]).to start_with("/oauth/authorize?")
        expect(session[:requested_path]).to include("client_id=#{client.client_id}")
      end
    end

    context "when signed in as an appropriate body user" do
      before { sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period) }

      it "renders the consent page and stores the request server-side" do
        get("/oauth/authorize", params:)

        expect(response).to be_successful
        expect(response.body).to include(client.name)
        expect(response.body).to include(appropriate_body_period.name)
        expect(session[:oauth_authorization_request]["client_id"]).to eq(client.client_id)
      end

      it "returns a bad request without redirecting when the client or redirect URI cannot be trusted" do
        get("/oauth/authorize", params: params.merge(client_id: "unknown"))
        expect(response).to have_http_status(:bad_request)

        get("/oauth/authorize", params: params.merge(redirect_uri: "https://evilcorp.com/callback"))
        expect(response).to have_http_status(:bad_request)
      end

      it "redirects to the vendor with an OAuth error for recoverable problems" do
        get("/oauth/authorize", params: params.merge(response_type: "token"))
        expect(response).to redirect_to(
          "#{redirect_uri}?error=invalid_request&error_description=Response+type+is+not+included+in+the+list&state=xyz"
        )
      end
    end
  end

  describe "DELETE /oauth/authorize" do
    before { sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period) }

    it "redirects to the vendor with access_denied and forgets the request" do
      get("/oauth/authorize", params:)

      delete("/oauth/authorize")

      expect(response).to redirect_to("#{redirect_uri}?error=access_denied&error_description=User+refused+connection&state=xyz")
      expect(session[:oauth_authorization_request]).to be_nil
    end

    it "returns a bad request when no authorization request is in progress" do
      delete("/oauth/authorize")

      expect(response).to have_http_status(:bad_request)
    end
  end
end
