RSpec.describe "OpenAPI documentation", type: :request do
  include_context "with authorization for api doc request"

  describe "GET /api/v3/delivery-partners" do
    before { FactoryBot.create(:lead_provider_delivery_partnership, lead_provider:) }

    it "returns delivery partners" do
      get "/api/v3/delivery-partners",
          headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)

      expect_response_to_match_open_api(
        endpoint: OpenAPI::Endpoints::V3::DeliveryPartners::Index
      )

      capture_open_api_response_example(
        endpoint: OpenAPI::Endpoints::V3::DeliveryPartners::Index,
        status: response.status,
        example: response.parsed_body
      )
    end
  end
end
