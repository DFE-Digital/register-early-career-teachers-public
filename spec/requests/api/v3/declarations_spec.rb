RSpec.describe "Participant declarations API", type: :request do
  describe "#create" do
    let(:path) { api_v3_declarations_path }

    it_behaves_like "a token authenticated endpoint", :post

    it "returns method not allowed" do
      authenticated_api_post path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#index" do
    let(:path) { api_v3_declarations_path }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    let(:path) { api_v3_declaration_path(123) }

    it_behaves_like "a token authenticated endpoint", :get

    it "returns method not allowed" do
      authenticated_api_get path
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
