require "swagger_helper"

RSpec.describe "Induction appropriate bodies endpoint", openapi_spec: "induction/v1/swagger.yaml", type: :request do
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:Authorization) { basic_auth_headers(client:).fetch("Authorization") }

  let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }

  document_api(get: "/api/induction/v1/appropriate-bodies") do
    described_as "List appropriate bodies"
    tagged_as "Appropriate bodies"
    secured_by :client_credentials

    responds_with 200, "Appropriate bodies" do
      schema type: :array, items: API::Induction::V1::AppropriateBodySerializer.openapi_ref
    end

    responds_with 401, "The client credentials are invalid" do
      let(:Authorization) { basic_auth_headers(client:, secret: "wrong").fetch("Authorization") }

      serialized_using API::OAuth::ErrorSerializer, include_namespace: true
    end

    responds_with 429, "Too many requests. Retry after the rate limit period has passed.", rack_attack: true do
      before do
        allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
        allow(Rack::Attack.throttles["API requests by auth token"]).to receive(:limit).and_return(0)
      end
    end
  end
end
