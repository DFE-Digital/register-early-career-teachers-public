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
      style: :string,
      required: true
    }]
  end

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/schools",
                    tag: "Schools",
                    resource_description: "schools scoped to cohort",
                    response_schema_ref: "#/components/schemas/SchoolsResponse",
                    filter_schema_ref: "#/components/schemas/SchoolsFilter",
                    default_sortable: true
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/schools/{id}",
                    tag: "Schools",
                    resource_description: "school scoped to cohort",
                    response_schema_ref: "#/components/schemas/SchoolResponse",
                    filter_schema_ref: "#/components/schemas/SchoolFilter",
                  } do
    let(:resource) { school }
  end
end
