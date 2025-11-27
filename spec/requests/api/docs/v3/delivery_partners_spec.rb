require "swagger_helper"

RSpec.describe "Delivery partners endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:resource) { delivery_partnership.delivery_partner }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/delivery-partners",
                    tag: "Delivery Partners",
                    resource_description: "Retrieve multiple delivery partners",
                    response_description: "A list of delivery partners",
                    response_schema_ref: "#/components/schemas/DeliveryPartnersResponse",
                    filter_schema_ref: "#/components/schemas/DeliveryPartnersFilter",
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/delivery-partners/{id}",
                    tag: "Delivery Partners",
                    resource_description: "Retrieve a single delivery partner",
                    response_description: "A single delivery partner",
                    response_schema_ref: "#/components/schemas/DeliveryPartnerResponse",
                  } do
  end
end
