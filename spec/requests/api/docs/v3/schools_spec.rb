require "swagger_helper"

RSpec.describe "Schools endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:resource) { FactoryBot.create(:school, :eligible, :with_induction_tutor) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, school: resource, lead_provider_delivery_partnership:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:contract_period) { lead_provider_delivery_partnership.contract_period }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school: resource) }
  let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period:, school_partnership:) }
  let(:"filter[cohort]") { contract_period.year }

  before do |example|
    # Required to send the required filter[cohort] parameter in the
    # request to pass the filter validation. This is a workaround and
    # the only way to pass nested query string parameters correctly.
    example.metadata[:example_group][:operation][:parameters] += [{
      name: "filter[cohort]",
      in: :query,
      style: :string,
      required: true
    }]
  end

  after do |example|
    # When dry-run is `false` the above filter is appended to the schema.
    # As we already define the full filter schema we need to remove it here
    # to avoid duplication.
    example.metadata[:example_group][:operation][:parameters].pop
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
