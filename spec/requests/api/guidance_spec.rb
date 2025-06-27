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

  describe "GET /api/early-career-training-programme-guidance" do
    before { get(api_guidance_page_path('early-career-training-programme-guidance')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/how-to-use-api" do
    before { get(api_guidance_page_path('how-to-use-api')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end

  describe "GET /api/technical-documentation" do
    before { get(api_guidance_page_path('technical-documentation')) }

    it "returns http success" do
      expect(response).to be_successful
    end
  end
end
