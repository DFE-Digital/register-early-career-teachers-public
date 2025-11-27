require "swagger_helper"

describe "Unfunded mentors endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml" do
  include MentorshipPeriodHelpers

  include_context "with authorization for api doc request"

  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider:
    )
  end
  let(:school_partnership) do
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
  end
  let!(:unfunded_mentor) do
    create_mentorship_period_for(mentee_school_partnership: school_partnership).mentor.teacher
  end

  let(:resource) { unfunded_mentor }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/unfunded-mentors",
                    tag: "Unfunded mentors",
                    resource_description: "Retrieve multiple unfunded mentors",
                    response_description: "A list of unfunded mentors",
                    response_schema_ref: "#/components/schemas/UnfundedMentorsResponse",
                    filter_schema_ref: "#/components/schemas/UnfundedMentorsFilter",
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/unfunded-mentors/{id}",
                    tag: "Unfunded mentors",
                    resource_description: "Retrieve a single unfunded mentor",
                    response_description: "A single unfunded mentor",
                    response_schema_ref: "#/components/schemas/UnfundedMentorResponse",
                  } do
  end
end
