require "swagger_helper"

RSpec.describe "Hello client endpoint", openapi_spec: "hello/swagger.yaml", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client, name: "Vendor Ltd") }
  let(:Authorization) { basic_auth_headers(client:).fetch("Authorization") }

  document_api(get: "/api/hello/client") do
    described_as "Check your client credentials identify your API client"
    tagged_as "Hello world"
    secured_by :client_credentials

    responds_with 200, "The API client the credentials belong to" do
      serialized_using API::Hello::ClientSerializer
    end

    responds_with 401, "The client credentials are invalid" do
      let(:Authorization) { basic_auth_headers(client:, secret: "wrong").fetch("Authorization") }

      serialized_using API::OAuth::ErrorSerializer
    end

    responds_with 429, "Too many requests. Retry after the rate limit period has passed.", rack_attack: true do
      before do
        allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
        allow(Rack::Attack.throttles["API requests by auth token"]).to receive(:limit).and_return(0)
      end
    end
  end
end
