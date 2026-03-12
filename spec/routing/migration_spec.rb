describe "Migration routes" do
  context "when enable_migration_interface = true" do
    before { allow(Rails.application.config).to receive(:enable_migration_interface).and_return(true) }

    it "permits access to the API routes" do
      expect(get: "/migration").to route_to(controller: "migration/migrations", action: "index")
    end
  end

  context "when enable_migration_interface = false" do
    before { allow(Rails.application.config).to receive(:enable_migration_interface).and_return(false) }

    it "prevents access to the API routes" do
      expect(get: "/migration").not_to be_routable
    end
  end
end
