RSpec.describe "Statements API", type: :request do
  let(:serializer) { StatementSerializer }
  let(:query) { Statements::Query }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }

  def create_resource(active_lead_provider:)
    FactoryBot.create(:statement, active_lead_provider:)
  end

  describe "#index" do
    let(:path) { api_v3_statements_path }

    def apply_expected_order(resources)
      resources.sort_by(&:payment_date)
    end

    it_behaves_like "a paginated endpoint"
    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a filter by multiple cohorts (contract_period year) endpoint"
    it_behaves_like "a filter by updated_since endpoint"
    it_behaves_like "an index endpoint"
  end

  describe "#show" do
    let(:resource) { create_resource(active_lead_provider:) }
    let(:path_id) { resource.api_id }
    let(:path) { api_v3_statement_path(path_id) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a show endpoint"
    it_behaves_like "a filter by lead provider endpoint"
  end
end
