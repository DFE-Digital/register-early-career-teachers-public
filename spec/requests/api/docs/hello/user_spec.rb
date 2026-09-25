require "swagger_helper"

RSpec.describe "Hello user endpoint", openapi_spec: "hello/swagger.yaml", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:Authorization) { bearer_auth_headers(authorization:).fetch("Authorization") }

  document_api(get: "/api/hello/user") do
    described_as "Check your access token identifies an appropriate body"
    tagged_as "Hello world"
    secured_by :bearer

    responds_with 200, "The appropriate body the access token was issued to" do
      serialized_using API::Hello::UserSerializer
    end

    responds_with 401, "The access token is missing, unknown, expired or revoked. A missing token returns no body." do
      let(:Authorization) { bearer_auth_headers(authorization:, token: "unknown").fetch("Authorization") }

      serialized_using API::OAuth::ErrorSerializer

      context "with an expired token" do
        let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_expired_token) }
        let(:Authorization) { bearer_auth_headers(authorization:).fetch("Authorization") }

        run_test!
      end

      context "with a revoked token" do
        let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, :revoked) }
        let(:Authorization) { bearer_auth_headers(authorization:).fetch("Authorization") }

        run_test!
      end
    end
  end
end
