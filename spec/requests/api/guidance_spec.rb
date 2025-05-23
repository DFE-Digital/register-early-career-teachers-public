RSpec.describe "API Guidance pages" do
  describe "GET /api/guidance" do
    before { get(api_guidance_path) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/release_notes" do
    before { get(api_guidance_release_notes_path) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/page-1" do
    before { get(api_guidance_page_path('page-1')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end
end
