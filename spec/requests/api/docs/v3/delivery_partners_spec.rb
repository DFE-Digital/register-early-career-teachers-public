require "swagger_helper"

RSpec.describe "Delivery partners endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  before { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:) }

  document_api(get: "/api/v3/delivery-partners") do
    described_as "Retrieve multiple delivery partners"
    tagged_as "Delivery Partners"

    with_query_parameters_serialized_using(
      API::PaginationSerializer,
      API::DeliveryPartners::FilterSerializer
    )

    responds_with 200, "A list of delivery partners" do
      a_list_serialized_using API::DeliveryPartnerSerializer
    end
  end
end
