describe "API routes" do
  it "permits access to the API routes and guidance" do
    expect(get: "/api/v3/participants").to route_to(controller: "api/v3/participants", action: "index")
    expect(get: "/api/guidance").to route_to(controller: "api/guidance", action: "show")
    expect(get: "/api/docs/v3").to route_to(controller: "api/documentation", action: "index", version: "v3")
  end
end
