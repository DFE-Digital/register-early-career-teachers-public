RSpec.describe API::TokenAuthenticatable, type: :request do
  APIRoute.with_concern(described_class, only: %i[training]).each do |route|
    context "on #{route}" do
      it "rejects a missing token" do
        process(route.verb, route.path, as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "HTTP Token: Access denied")
      end

      it "rejects an unknown token" do
        process(route.verb, route.path, headers: { "Authorization" => "Bearer unknown" }, as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "HTTP Token: Access denied")
      end

      it "rejects a revoked token" do
        api_token = FactoryBot.create(:api_token)
        token = api_token.token
        API::TokenManager.revoke_lead_provider_api_token!(api_token:)

        process(route.verb, route.path, headers: { "Authorization" => "Bearer #{token}" }, as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "HTTP Token: Access denied")
      end

      it "rejects an OAuth API token" do
        authorization = FactoryBot.create(:api_oauth_authorization, :with_token)
        process(route.verb, route.path, headers: bearer_auth_headers(authorization:), as: :json)

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "HTTP Token: Access denied")
      end
    end
  end
end
