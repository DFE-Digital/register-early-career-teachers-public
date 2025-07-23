require "swagger_helper"

RSpec.describe "Schools endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:school) { FactoryBot.create(:school, :eligible) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let(:"filter[cohort]") { school_partnership.contract_period.year }

  before do |example|
    example.metadata[:example_group][:operation][:parameters] += [{
      name: "filter[cohort]",
      in: :query,
      type: :string,
      required: true
    }]
  end

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/schools",
                  "Schools",
                  "ECF schools scoped to cohort",
                  "#/components/schemas/SchoolsFilter",
                  "#/components/schemas/SchoolsResponse",
                  true

  it_behaves_like "an API show endpoint documentation",
                  "/api/v3/schools/{id}",
                  "Schools",
                  "ECF school scoped to cohort",
                  "#/components/schemas/SchoolResponse" do
    let(:resource) { school }
  end
end
