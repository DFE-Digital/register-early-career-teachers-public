RSpec.describe API::OAuth::TokenAuthenticable, type: :request do
  APIRoute.with_concern(described_class, only: %i[induction hello oauth]).each do |route|
    context "on #{route}" do
      it "rejects a missing token" do
        process(route.verb, route.path, as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq("Bearer")
        expect(response.body).to be_empty
      end

      it "rejects an unknown token" do
        process(route.verb, route.path, headers: { "Authorization" => "Bearer unknown" }, as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Bearer error="invalid_token"))
        expect(response.parsed_body).to eq("error" => "invalid_token")
      end

      it "rejects a legacy lead provider API token" do
        api_token = FactoryBot.create(:api_token)
        process(route.verb, route.path, headers: api_headers(token: api_token.token), as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Bearer error="invalid_token"))
        expect(response.parsed_body).to eq("error" => "invalid_token")
      end

      it "rejects an expired token" do
        expired = FactoryBot.create(:api_oauth_authorization, :with_expired_token, token: "expired-token")
        process(route.verb, route.path, headers: bearer_auth_headers(authorization: expired, token: "expired-token"), as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Bearer error="invalid_token"))
        expect(response.parsed_body).to eq("error" => "invalid_token")
      end

      it "rejects a revoked token" do
        revoked = FactoryBot.create(:api_oauth_authorization, :with_token, :revoked)
        process(route.verb, route.path, headers: bearer_auth_headers(authorization: revoked), as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Bearer error="invalid_token"))
        expect(response.parsed_body).to eq("error" => "invalid_token")
      end
    end
  end
end
