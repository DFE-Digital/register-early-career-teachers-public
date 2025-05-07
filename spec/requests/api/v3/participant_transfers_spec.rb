RSpec.describe "Participant transfers API", type: :request do
  describe "#index" do
    it "returns method not allowed" do
      api_get(api_v3_transfers_path)
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      api_get(api_v3_participant_transfers_path(123))
      expect(response).to be_method_not_allowed
    end
  end
end
