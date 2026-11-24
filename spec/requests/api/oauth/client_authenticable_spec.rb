RSpec.describe API::OAuth::ClientAuthenticable, type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client) }

  APIRoute.with_concern(described_class, only: %i[induction hello oauth]).each do |route|
    context "on #{route}" do
      it "rejects missing credentials" do
        process(route.verb, route.path)

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Basic realm="Application"))
        expect(response.parsed_body).to eq("error" => "invalid_client")
      end

      it "rejects a wrong secret" do
        process(route.verb, route.path, headers: basic_auth_headers(client:, secret: "wrong"))

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Basic realm="Application"))
        expect(response.parsed_body).to eq("error" => "invalid_client")
      end

      it "rejects an unknown client" do
        process(route.verb, route.path, headers: basic_auth_headers(client: FactoryBot.build(:api_oauth_client)))

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["WWW-Authenticate"]).to eq(%(Basic realm="Application"))
        expect(response.parsed_body).to eq("error" => "invalid_client")
      end
    end
  end
end
