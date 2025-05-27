RSpec.describe "Statements API", type: :request do
  describe "#index" do
    let(:path) { api_v3_statements_path }

    it_behaves_like "a token authenticated endpoint", :get
    it_behaves_like "an error rescuable endpoint"

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
