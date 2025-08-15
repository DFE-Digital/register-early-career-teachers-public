require "swagger_helper"

RSpec.describe "Partnerships endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:resource) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/partnerships",
                    tag: "Partnerships",
                    resource_description: "partnerships",
                    response_schema_ref: "#/components/schemas/PartnershipsResponse",
                    filter_schema_ref: "#/components/schemas/PartnershipsFilter",
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/partnerships/{id}",
                    tag: "Partnerships",
                    resource_description: "partnership",
                    response_schema_ref: "#/components/schemas/PartnershipResponse",
                  } do
  end
end
