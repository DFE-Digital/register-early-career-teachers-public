RSpec.describe "Statements API", type: :request do
  let(:current_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:query) { Statements::Query }
  let(:serializer) { API::StatementSerializer }

  describe "#index" do
    let(:path) { api_v3_statements_path }

    def create_resource(**attrs)
      FactoryBot.create(:statement, **attrs)
    end

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an error rescuable endpoint"
    it_behaves_like "an index endpoint with filter by registration_period"
    it_behaves_like "an index endpoint with filter by updated_since"

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    let(:path) { api_v3_statement_path(123) }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an error rescuable endpoint"

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end
end
