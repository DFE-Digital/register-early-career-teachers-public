RSpec.describe "Partnerships API", type: :request do
  let(:serializer) { API::SchoolPartnershipSerializer }
  let(:serializer_options) { {lead_provider:} }
  let(:query) { API::SchoolPartnerships::Query }
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
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
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

  describe "#create" do
    let(:path) { api_v3_partnerships_path }
    let(:service) { API::SchoolPartnerships::Create }
    let(:resource_type) { SchoolPartnership }
    let(:delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
    let(:school) { FactoryBot.create(:school, :eligible) }
    let(:service_args) do
      {
        lead_provider_id: active_lead_provider.lead_provider_id,
        contract_period_year: active_lead_provider.contract_period_year.to_s,
        school_api_id: school.api_id,
        delivery_partner_api_id: delivery_partnership.delivery_partner.api_id
      }
    end
    let(:params) do
      {
        data: {
          type: "partnership",
          attributes: {
            school_id: school.api_id,
            delivery_partner_id: delivery_partnership.delivery_partner.api_id,
            cohort: active_lead_provider.contract_period_year
          }
        }
      }
    end

    it_behaves_like "a token authenticated endpoint", :post
    it_behaves_like "an API create endpoint"
  end

  describe "#update" do
    let(:path) { api_v3_partnership_path(resource.api_id) }
    let(:service) { API::SchoolPartnerships::Update }
    let(:resource_type) { SchoolPartnership }
    let(:resource) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
    let(:other_delivery_partner) do
      other_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
      other_delivery_partnership.delivery_partner
    end
    let(:service_args) do
      {
        school_partnership_id: resource.id,
        delivery_partner_api_id: other_delivery_partner.api_id
      }
    end
    let(:params) do
      {
        data: {
          type: "partnership",
          attributes: {
            delivery_partner_id: other_delivery_partner.api_id
          }
        }
      }
    end

    it_behaves_like "a token authenticated endpoint", :put
    it_behaves_like "an API update endpoint"
  end
end
