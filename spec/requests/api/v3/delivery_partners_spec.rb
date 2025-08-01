RSpec.describe "Delivery partners API", type: :request do
  let(:serializer) { DeliveryPartnerSerializer }
  let(:serializer_options) { { lead_provider: } }
  let(:query) { DeliveryPartners::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:)
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:).delivery_partner
  end

  describe "#index" do
    let(:path) { api_v3_delivery_partners_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a paginated endpoint"
    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
    it_behaves_like "an index endpoint"
    it_behaves_like "a sortable endpoint"
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_delivery_partner_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
  end
end
