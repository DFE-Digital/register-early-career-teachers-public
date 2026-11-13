describe "API routes" do
  it "permits access to the API routes and guidance" do
    expect(get: "/api/v3/participants").to route_to(controller: "api/v3/participants", action: "index")
    expect(get: "/api/docs/training/guidance").to route_to(controller: "api/documentation/training/guidance", action: "show")
    expect(get: "/api/docs/training/v3").to route_to(controller: "api/documentation/training/v3/documentation", action: "index")
  end

  context "when the training API feature flag is true", with_feature_flags: { enable_training_api: true } do
    it "permits access to the Training API routes" do
      expect(get: "/api/docs/training/v4").to route_to(controller: "api/training/v4/documentations", action: "show")
    end
  end

  context "when the training API feature flag is false", with_feature_flags: { enable_training_api: false } do
    it "removes access to the Training API routes" do
      expect(get: "/api/docs/training/v4").not_to route_to(controller: "api/training/v4/documentations", action: "show")
    end
  end
end
