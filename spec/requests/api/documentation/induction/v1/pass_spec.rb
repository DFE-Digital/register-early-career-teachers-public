require "swagger_helper"

RSpec.describe "Induction passes endpoint", openapi_spec: "induction/v1/swagger.yaml", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:Authorization) { bearer_auth_headers(authorization:).fetch("Authorization") }
  let(:teacher_trn) { FactoryBot.create(:induction_period, :unfinished, appropriate_body_period:).trn }
  let(:pass) { { finished_on: 1.day.ago.to_date.iso8601, number_of_terms: 3 } }

  document_api(post: "/api/induction/v1/teachers/{teacher_trn}/pass") do
    described_as "Pass an early career teacher's induction"
    tagged_as "Inductions"
    secured_by :bearer
    consumes "application/json"

    parameter name: :teacher_trn, in: :path, type: :string, description: "The teacher reference number.", example: "1234567"
    parameter name: :pass, in: :body, schema: { "$ref": "#/components/schemas/PassRequest" }

    responds_with 200, "The early career teacher's induction was passed" do
      serialized_using API::Induction::V1::OutcomeSerializer
    end

    responds_with 400, "The request body is missing or is not a JSON object" do
      let(:pass) { nil }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 401, "The access token is missing, unknown, expired or revoked. A missing token returns no body." do
      let(:Authorization) { bearer_auth_headers(authorization:, token: "unknown").fetch("Authorization") }

      serialized_using API::OAuth::ErrorSerializer, include_namespace: true
    end

    responds_with 404, "No teacher with the TRN has an ongoing induction with you" do
      let(:teacher_trn) { "0000000" }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 422, "The induction could not be passed" do
      let(:pass) { super().merge(number_of_terms: nil) }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 429, "Too many requests. Retry after the rate limit period has passed.", rack_attack: true do
      before do
        allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
        allow(Rack::Attack.throttles["API requests by auth token"]).to receive(:limit).and_return(0)
      end
    end
  end
end
