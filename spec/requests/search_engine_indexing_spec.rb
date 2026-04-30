describe "Search engine indexing", type: :request do
  context "when ALLOW_INDEXING is true (default)" do
    before do
      allow(Rails.application.config).to receive(:search_engine_indexing_enabled).and_return(true)
    end

    it "allows the home page to be indexed" do
      get("/")

      expect(response.headers["X-Robots-Tag"]).to eq("all")
    end

    it "allows the appropriate body landing page to be indexed" do
      get("/appropriate-body")

      expect(response.headers["X-Robots-Tag"]).to eq("all")
    end

    it "prevents other pages from being indexed" do
      get("/sign-in")

      expect(response.headers["X-Robots-Tag"]).to eq("none")
    end
  end

  context "when ALLOW_INDEXING is false" do
    before do
      allow(Rails.application.config).to receive(:search_engine_indexing_enabled).and_return(false)
    end

    it "prevents the home page from being indexed" do
      get("/")

      expect(response.headers["X-Robots-Tag"]).to eq("none")
    end

    it "prevents the appropriate body landing page from being indexed" do
      get("/appropriate-body")

      expect(response.headers["X-Robots-Tag"]).to eq("none")
    end
  end
end
