describe "API routes" do
  it "permits access to the API routes and guidance" do
    expect(get: "/api/v3/participants").to route_to(controller: "api/v3/participants", action: "index")
    expect(get: "/api/docs/lead-provider/guidance").to route_to(controller: "api/docs/lead_provider/guidance", action: "show")
    expect(get: "/api/docs/lead-provider/v3").to route_to(controller: "api/docs/lead_provider/v3/documentation", action: "index")
  end
end
