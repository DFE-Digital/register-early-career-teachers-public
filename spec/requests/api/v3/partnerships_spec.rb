RSpec.describe "Partnerships API", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }

  describe "#create" do
    it "returns method not allowed" do
      api_post(api_v3_partnerships_path)
      expect(response).to be_method_not_allowed
    end
  end

  describe "#index" do
    it "returns a successful response" do
      api_get(api_v3_partnerships_path)

      expect(response).to be_successful
      expect(parsed_response["data"]).to be_empty
    end
  end

  describe "#show" do
    it "returns a successful response" do
      api_get(api_v3_partnership_path(123))

      expect(response).to be_successful
      expect(parsed_response["data"]).to be_empty
    end
  end

  describe "#update" do
    it "returns method not allowed" do
      api_put(api_v3_partnership_path(123))
      expect(response).to be_method_not_allowed
    end
  end
end
