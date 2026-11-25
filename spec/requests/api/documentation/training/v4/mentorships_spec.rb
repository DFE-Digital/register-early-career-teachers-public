require "swagger_helper"

RSpec.describe "Training mentorships endpoint", openapi_spec: "training/v4/swagger.yaml", type: :request do
  let(:api_token) { FactoryBot.create(:api_token) }
  let(:Authorization) { "Bearer #{api_token.token}" }
  let(:year) { FactoryBot.create(:contract_period, year: 2026).year }

  document_api(get: "/api/training/v4/cohorts/{year}/mentorships") do
    described_as "Placeholder for listing mentorships in a cohort (returns no data yet)"
    tagged_as "Mentorships"
    identified_as "getCohortMentorships"
    secured_by :bearer

    parameter name: :year, in: :path, type: :integer, required: true, description: "The cohort year.", example: 2026

    responds_with 200, "An empty response. This endpoint is a placeholder." do
    end

    responds_with 401, "The lead provider API token is missing, unknown or revoked." do
      let(:Authorization) { "Bearer unknown-token" }

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
