require "swagger_helper"

RSpec.describe "Declarations endpoint", :with_metadata, openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      lead_provider: active_lead_provider.lead_provider,
      year: active_lead_provider.contract_period.year
    )
  end
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      :with_school_partnership,
      school_partnership:
    )
  end
  let(:declaration) { FactoryBot.create(:declaration, training_period:) }

  let(:resource) { declaration }

  it_behaves_like "an API index endpoint documentation",
                  {
                    url: "/api/v3/participant-declarations",
                    tag: "Declarations",
                    resource_description: "Retrieve multiple declarations",
                    response_description: "A list of declarations",
                    response_schema_ref: "#/components/schemas/DeclarationsResponse",
                    filter_schema_ref: "#/components/schemas/DeclarationsFilter",
                  }

  it_behaves_like "an API show endpoint documentation",
                  {
                    url: "/api/v3/participant-declarations/{id}",
                    tag: "Declarations",
                    resource_description: "Retrieve a single declaration",
                    response_description: "A single declaration",
                    response_schema_ref: "#/components/schemas/DeclarationResponse",
                  }

  it_behaves_like "an API update endpoint documentation",
                  {
                    url: "/api/v3/participant-declarations/{id}/void",
                    tag: "Declarations",
                    resource_description: "Void a declaration",
                    response_description: "The declaration being voided",
                    response_schema_ref: "#/components/schemas/DeclarationResponse",
                    accepts_request_body: false
                  } do
    let(:params) { {} }
    let(:declaration) do
      FactoryBot.create(:declaration, :payable, training_period:)
    end

    let(:invalid_params) { {} }
    let(:invalid_resource) do
      FactoryBot.create(:declaration, :voided, training_period:)
    end
  end
end
