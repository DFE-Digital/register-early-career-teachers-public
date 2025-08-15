RSpec.describe "Partnerships API", type: :request do
  let(:serializer) { PartnershipSerializer }
  let(:serializer_options) { { lead_provider: } }
  let(:query) { SchoolPartnerships::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
  end

  describe "#index" do
    let(:path) { api_v3_partnerships_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a paginated endpoint"
    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a filter by a single cohort (contract_period year) endpoint"
    it_behaves_like "a filter by updated_since endpoint"
    it_behaves_like "a filter by delivery_partner_id endpoint"
    it_behaves_like "an index endpoint"
    it_behaves_like "a sortable endpoint"
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_partnership_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by cohort endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
    it_behaves_like "a does not filter by delivery_partner_id endpoint"
  end

  describe "# create" do
    let(:path) { api_v3_partnerships_path }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_post path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#update" do
    let(:path) { api_v3_partnership_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end
end
