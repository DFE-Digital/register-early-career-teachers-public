RSpec.describe "Schools API", type: :request do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }
  let(:contract_period) { active_lead_provider.contract_period }
  let(:serializer) { SchoolSerializer }
  let(:serializer_options) { { contract_period_id: contract_period.id, lead_provider_id: lead_provider.id } }
  let(:endpoint_mandatory_params) { { filter: { cohort: contract_period.id } } }

  def create_resource(active_lead_provider:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:).school
  end

  describe "#index" do
    let(:path) { api_v3_schools_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a sortable endpoint"
    it_behaves_like "a filter by a single cohort (contract_period year) endpoint"
    it_behaves_like "a filter by updated_since endpoint"
    it_behaves_like "a filter validatable endpoint", %i[cohort]
    it_behaves_like "a filter by urn endpoint"
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_school_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
  end
end
