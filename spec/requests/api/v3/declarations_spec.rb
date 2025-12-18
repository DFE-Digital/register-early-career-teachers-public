RSpec.describe "Declarations API", type: :request do
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_options) { {} }
  let(:query) { API::Declarations::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:, teacher: nil)
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
    school_partnership = FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
    teacher ||= FactoryBot.create(:teacher)

    ect_at_school_period = FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, finished_on: nil, teacher:, school: school_partnership.school)
    training_period = FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 1.year.ago, finished_on: nil, school_partnership:)

    FactoryBot.create(:declaration, training_period:)
  end

  describe "#index" do
    let(:path) { api_v3_declarations_path }

    def apply_expected_order(resources)
      resources.sort_by(&:created_at)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an index endpoint"
    it_behaves_like "a paginated endpoint"
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
    it_behaves_like "a filter by delivery_partner_id endpoint"
    it_behaves_like "a filter by participant_id endpoint"
    it_behaves_like "a filter by updated_since endpoint", updated_at_column: :updated_at
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_declaration_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a does not filter by cohort endpoint"
    it_behaves_like "a does not filter by delivery_partner_id endpoint"
    it_behaves_like "a does not filter by participant_id endpoint"
    it_behaves_like "a does not filter by updated_since endpoint"
  end

  describe "#create" do
    let(:path) { api_v3_declarations_path }

    it "returns method not allowed" do
      authenticated_api_post path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#void" do
    let(:path) { api_v3_declaration_void_path(123) }

    it_behaves_like "a token authenticated endpoint", :put

    it "returns method not allowed" do
      authenticated_api_put path
      expect(response).to be_method_not_allowed
    end
  end
end
