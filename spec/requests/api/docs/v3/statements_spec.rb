require "swagger_helper"

RSpec.describe "Statements endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:statement) { FactoryBot.create(:statement, active_lead_provider:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/statements",
                  "Statements",
                  "statements as part of which the DfE will make output payments for participants",
                  "#/components/schemas/StatementsFilter",
                  "#/components/schemas/StatementsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v3/statements/{id}",
                  "Statements",
                  "financial statement",
                  "#/components/schemas/StatementResponse" do
    let(:resource) { statement }
  end
end
