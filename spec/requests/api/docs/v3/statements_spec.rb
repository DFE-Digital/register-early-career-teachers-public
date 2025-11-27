require "swagger_helper"

RSpec.describe "Statements endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:statement) { FactoryBot.create(:statement, active_lead_provider:) }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/statements",
                    tag: "Statements",
                    resource_description: "Retrieve multiple financial statement details",
                    response_description: "A list of financial statements details",
                    response_schema_ref: "#/components/schemas/StatementsResponse",
                    filter_schema_ref: "#/components/schemas/StatementsFilter",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/statements/{id}",
                    tag: "Statements",
                    resource_description: "Retrieve a single financial statement details",
                    response_description: "A single financial statement details",
                    response_schema_ref: "#/components/schemas/StatementResponse",
                  } do
    let(:resource) { statement }
  end
end
