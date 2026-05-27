RSpec.describe "Banner", type: :request do
  context "when maintenance is pending" do
    let(:content) { "This service will be unavailable" }

    context "when ENABLE_MAINTENANCE_BANNER is true" do
      before do
        allow(Rails.application.config).to receive(:enable_maintenance_banner).and_return(true)
      end

      it "displays on default layout" do
        get "/support"
        expect(response.body).to include(content)
      end

      it "displays on full layout" do
        get "/access-denied"
        expect(response.body).to include(content)
      end
    end

    context "when ENABLE_MAINTENANCE_BANNER is false" do
      it "does not display on default layout" do
        get "/support"
        expect(response.body).not_to include(content)
      end

      it "does not display on full layout" do
        get "/access-denied"
        expect(response.body).not_to include(content)
      end
    end
  end

  context "when an incident occurs" do
    let(:content) { "There are intermittent issues accessing the service" }

    context "when ENABLE_INCIDENT_BANNER is true" do
      before do
        allow(Rails.application.config).to receive(:enable_incident_banner).and_return(true)
      end

      it "displays on default layout" do
        get "/support"
        expect(response.body).to include(content)
      end

      it "displays on full layout" do
        get "/access-denied"
        expect(response.body).to include(content)
      end
    end

    context "when ENABLE_INCIDENT_BANNER is false" do
      it "does not display on default layout" do
        get "/support"
        expect(response.body).not_to include(content)
      end

      it "does not display on full layout" do
        get "/access-denied"
        expect(response.body).not_to include(content)
      end
    end
  end

  context "when registration window is closed" do
    let(:content) { "Registration not currently open" }

    context "between 1-14 June 2026" do
      before { travel_to Date.new(2026, 6, 7) }

      it "displays on default layout" do
        get "/support"
        expect(response.body).to include(content)
      end

      it "displays on full layout" do
        get "/access-denied"
        expect(response.body).to include(content)
      end
    end

    context "before 1 June 2026" do
      before { travel_to Date.new(2026, 5, 31) }

      it "does not display on default layout" do
        get "/support"
        expect(response.body).not_to include(content)
      end

      it "does not display on full layout" do
        get "/access-denied"
        expect(response.body).not_to include(content)
      end
    end

    context "from 15 June 2026" do
      before { travel_to Date.new(2026, 6, 15) }

      it "does not display on default layout" do
        get "/support"
        expect(response.body).not_to include(content)
      end

      it "does not display on full layout" do
        get "/access-denied"
        expect(response.body).not_to include(content)
      end
    end
  end
end
