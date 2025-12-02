describe "Search engine indexing", type: :request do
  context "when ALLOW_INDEXING is true (default)" do
    it "allows the site to be indexed" do
      get("/")

      expect(response.headers["X-Robots-Tag"]).to be_nil
    end
  end
end
