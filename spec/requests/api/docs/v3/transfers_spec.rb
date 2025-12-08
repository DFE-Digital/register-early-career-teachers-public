require "swagger_helper"

RSpec.describe "Tranfers endpoint", openapi_spec: "v3/swagger.yaml" do
  include SchoolTransferHelpers

  include_context "with authorization for api doc request"

  let(:transferred_teacher) { FactoryBot.create(:teacher) }
  let(:resource) { transferred_teacher }

  before do
    build_new_school_transfer(teacher: transferred_teacher, lead_provider:)

    # We need to manually refresh the metadata as we create lead providers
    # after training periods in build_new_school_transfer, and we don't
    # refresh metadata when lead providers are created.
    Metadata::Handlers::Teacher.new(transferred_teacher).refresh_metadata!
  end

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/participants/transfers",
                    tag: "Transfers",
                    resource_description: "Retrieve all participants with transfers",
                    response_description: "A list of participants with transfers",
                    response_schema_ref: "#/components/schemas/ParticipantsTransfersResponse",
                    filter_schema_ref: "#/components/schemas/ParticipantsTransfersFilter",
                    sorting_schema_ref: "#/components/schemas/SortingTimestamps",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/participants/{id}/transfers",
                    tag: "Transfers",
                    resource_description: "Retrieve transfers for a given participant",
                    response_description: "Transfers for a given participant",
                    response_schema_ref: "#/components/schemas/ParticipantTransfersResponse",
                  }
end
