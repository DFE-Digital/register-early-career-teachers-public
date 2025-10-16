require "swagger_helper"

RSpec.describe "Schools endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api request"

  let(:resource) { FactoryBot.create(:school, :eligible) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, school: resource, lead_provider_delivery_partnership:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:contract_period) { lead_provider_delivery_partnership.contract_period }
  let(:"filter[cohort]") { contract_period.year }

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
