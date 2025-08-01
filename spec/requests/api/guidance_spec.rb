RSpec.describe "API Guidance pages" do
  describe "GET /api/guidance" do
    before { get(api_guidance_path) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/release-notes" do
    before { get(api_guidance_release_notes_path) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/swagger-api-documentation" do
    before { get(api_guidance_page_path('swagger-api-documentation')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/sandbox" do
    before { get(api_guidance_page_path('sandbox')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/guidance-for-lead-providers" do
    before { get(api_guidance_page_path('guidance-for-lead-providers')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end
end
