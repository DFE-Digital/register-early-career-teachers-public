RSpec.describe "Unfunded mentors API", type: :request do
  describe "#index" do
    it "returns method not allowed" do
      api_get(api_v3_unfunded_mentors_path)
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      api_get(api_v3_unfunded_mentor_path(123))
      expect(response).to be_method_not_allowed
    end
  end
end
