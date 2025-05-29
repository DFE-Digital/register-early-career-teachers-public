RSpec.describe "Statements API", type: :request do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  describe "#index" do
    let(:path) { api_v3_statements_path }

    def create_resource(active_lead_provider:)
      FactoryBot.create(:statement, active_lead_provider:)
    end

    it_behaves_like "an error rescuable endpoint"
    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "a paginated endpoint"

    it "returns success" do
      authenticated_api_get path
      expect(response).to be_successful
    end
  end

  describe "#show" do
    let(:path) { api_v3_statement_path(123) }

    it_behaves_like "an error rescuable endpoint"
    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end
end
