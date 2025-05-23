RSpec.describe "Delivery partners API", type: :request do
  describe "#index" do
    let(:path) { api_v3_delivery_partners_path }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    let(:path) { api_v3_delivery_partner_path(123) }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end
end
