RSpec.describe "Schools API", type: :request do
  describe "#index" do
    it "returns method not allowed" do
      get api_v3_schools_path
      expect(response).to be_method_not_allowed
    end
  end

  describe "#show" do
    it "returns method not allowed" do
      get api_v3_school_path(123)
      expect(response).to be_method_not_allowed
    end
  end
end
