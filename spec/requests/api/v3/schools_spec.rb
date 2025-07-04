RSpec.describe "Schools API", type: :request do
  describe "#index" do
    let(:path) { api_v3_schools_path }

    it_behaves_like "a token authenticated endpoint", :get

    # TODO: implement when the endpoint is ready
    it "returns method not allowed", pending: 'endpoint implementation not ready yet' do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    let(:path) { api_v3_school_path(123) }

    it_behaves_like "a token authenticated endpoint", :get

    # TODO: implement when the endpoint is ready
    it "returns method not allowed", pending: 'endpoint implementation not ready yet' do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end
end
