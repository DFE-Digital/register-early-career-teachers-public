require "swagger_helper"

RSpec.describe "Schools endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:resource) { FactoryBot.create(:school, :eligible) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, school: resource) }
  let(:contract_period) { school_partnership.contract_period }
  let(:"filter[cohort]") { contract_period.year }

  before do |example|
    FactoryBot.create(:school_lead_provider_contract_period_metadata, school: resource, contract_period:, lead_provider: active_lead_provider.lead_provider)
    FactoryBot.create(:school_contract_period_metadata, school: resource, contract_period:)

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
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/schools/{id}",
                    tag: "Schools",
                    resource_description: "school scoped to cohort",
                    response_schema_ref: "#/components/schemas/SchoolResponse",
                    filter_schema_ref: "#/components/schemas/SchoolFilter",
                  } do
  end
end
