require "swagger_helper"

RSpec.describe "Delivery partners endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  before { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:) }

  it_behaves_like "an open API index endpoint documentation",
                  {
                    url: "/api/v3/delivery-partners",
                    tag: "Delivery Partners",
                    resource_description: "Retrieve multiple delivery partners",
                    response_description: "A list of delivery partners",

                    response_schema: API::DeliveryPartnerSerializer,

                    parameter_schemas: [
                      API::PaginationSerializer,
                      API::DeliveryPartners::FilterSerializer,
                    ],
                  }
end
