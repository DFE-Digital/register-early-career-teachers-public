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

  describe "GET /api/guidance/swagger-api-documentation" do
    before { get("/api/guidance/swagger-api-documentation") }

    it "redirects to the Swagger UI page" do
      expect(response).to redirect_to("/api/docs/v3")
    end
  end

  describe "GET /api/guidance-for-lead-providers/sandbox" do
    before { get(api_guidance_page_path("guidance-for-lead-providers/sandbox")) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/guidance-for-lead-providers" do
    before { get(api_guidance_page_path("guidance-for-lead-providers")) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end
end
