describe "API routes" do
  it "permits access to the API routes and guidance" do
    expect(get: "/api/v3/participants").to route_to(controller: "api/v3/participants", action: "index")
    expect(get: "/api/docs/training/guidance").to route_to(controller: "api/documentation/training/guidance", action: "show")
    expect(get: "/api/docs/training/v3").to route_to(controller: "api/documentation/training/v3/documentation", action: "index")
  end
end
