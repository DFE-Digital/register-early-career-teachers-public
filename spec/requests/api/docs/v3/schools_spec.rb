require "swagger_helper"

RSpec.describe "Schools endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:school) { FactoryBot.create(:school, :eligible) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/schools",
                  "Schools",
                  "ECF schools scoped to cohort",
                  "#/components/schemas/SchoolsResponse",
                  "#/components/schemas/SchoolsFilter",
                  true,
                  true

  it_behaves_like "an API show endpoint documentation",
                  "/api/v3/schools/{id}",
                  "Schools",
                  "ECF school scoped to cohort",
                  "#/components/schemas/SchoolResponse",
                  true do
    let(:resource) { school }
  end
end
