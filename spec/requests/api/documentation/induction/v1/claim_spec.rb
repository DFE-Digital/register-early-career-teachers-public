require "swagger_helper"

RSpec.describe "Induction claims endpoint", openapi_spec: "induction/v1/swagger.yaml", type: :request do
  include_context "test TRS API returns a teacher"

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:authorization) { FactoryBot.create(:api_oauth_authorization, :with_token, appropriate_body_period:) }
  let(:Authorization) { bearer_auth_headers(authorization:).fetch("Authorization") }
  let(:teacher_trn) { "1234567" }
  let(:claim) { { date_of_birth: "2001-05-13", started_on: 1.month.ago.to_date.iso8601, training_programme: "school_led" } }

  document_api(post: "/api/induction/v1/teachers/{teacher_trn}/claim") do
    described_as "Claim an early career teacher's induction"
    tagged_as "Inductions"
    secured_by :bearer
    consumes "application/json"

    parameter name: :teacher_trn, in: :path, type: :string, description: "The teacher reference number.", example: "1234567"
    parameter name: :claim, in: :body, schema: { "$ref": "#/components/schemas/ClaimRequest" }

    responds_with 201, "The early career teacher's induction was claimed" do
      serialized_using API::Induction::V1::ClaimSerializer
    end

    responds_with 400, "The request body is missing or is not a JSON object" do
      let(:claim) { nil }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 401, "The access token is missing, unknown, expired or revoked. A missing token returns no body." do
      let(:Authorization) { bearer_auth_headers(authorization:, token: "unknown").fetch("Authorization") }

      serialized_using API::OAuth::ErrorSerializer, include_namespace: true
    end

    responds_with 404, "No teacher was found with the TRN and date of birth" do
      include_context "test TRS API returns nothing"

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 409, "The teacher already has an ongoing induction period" do
      let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher: FactoryBot.create(:teacher, trn: teacher_trn)) }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 422, "The claim is not valid or the teacher is not eligible for induction" do
      let(:claim) { super().merge(date_of_birth: nil) }

      serialized_using API::Induction::V1::ErrorSerializer
    end

    responds_with 503, "The Teaching Record System is unavailable. Try again later." do
      include_context "test TRS API is unavailable"

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
