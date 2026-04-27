describe "API routes" do
  before { allow(Rails.application.config).to receive(:enable_api).and_return(enable_api) }

  context "when enabled" do
    let(:enable_api) { true }

    it "permits access to the API routes and guidance" do
      expect(get: "/api/v3/participants").to route_to(controller: "api/v3/participants", action: "index")
      expect(get: "/api/guidance").to route_to(controller: "api/guidance", action: "show")
      expect(get: "/api/docs/v3").to route_to(controller: "api/documentation", action: "index", version: "v3")
    end
  end

  context "when disabled" do
    let(:enable_api) { false }

    it "prevents access to the API routes" do
      expect(get: "/api/v3/participants").not_to be_routable
    end

    it "still permits access to guidance" do
      expect(get: "/api/guidance").to route_to(controller: "api/guidance", action: "show")
      expect(get: "/api/guidance/release-notes").to route_to(controller: "api/release_notes", action: "index")
      expect(get: "/api/guidance/some-page").to route_to(controller: "api/guidance", action: "page", page: "some-page")
    end

    it "still permits access to swagger docs" do
      expect(get: "/api/docs/v3").to route_to(controller: "api/documentation", action: "index", version: "v3")
    end
  end
end
