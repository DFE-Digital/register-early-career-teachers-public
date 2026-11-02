RSpec.describe "Notification banners", type: :request do
  # App layouts:
  # - application.html.erb
  #   - full.html.erb
  #   - two_thirds.html.erb
  #
  # API layouts:
  # - api_documentation.html.erb
  # - api/documentation/training/api_guidance.html.erb
  # - api/documentation/swagger.html.erb
  # - api/documentation/training/api_home.html.erb                 (no banners)

  let(:maintenance_text) { "This service will be unavailable" }
  let(:incident_text) { "There are intermittent issues accessing the service" }
  let(:maintenance_banner) { false }
  let(:incident_banner) { false }
  let(:personas) { false }

  before do
    allow(Rails.application.config).to receive_messages(
      enable_maintenance_banner: maintenance_banner,
      enable_incident_banner: incident_banner,
      enable_personas: personas
    )
    get path
  end

  context "on the full layout" do
    let(:path) { "/personas" }
    let(:personas) { true }

    describe "the maintenance banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(maintenance_text) }
      end

      context "when enabled" do
        let(:maintenance_banner) { true }

        it { expect(response.body).to include(maintenance_text) }
      end
    end

    describe "the incident banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(incident_text) }
      end

      context "when enabled" do
        let(:incident_banner) { true }

        it { expect(response.body).to include(incident_text) }
      end
    end
  end

  context "on the two_thirds layout" do
    let(:path) { "/support" }

    describe "the maintenance banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(maintenance_text) }
      end

      context "when enabled" do
        let(:maintenance_banner) { true }

        it { expect(response.body).to include(maintenance_text) }
      end
    end

    describe "the incident banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(incident_text) }
      end

      context "when enabled" do
        let(:incident_banner) { true }

        it { expect(response.body).to include(incident_text) }
      end
    end
  end

  context "on the api_documentation layout" do
    let(:path) { "/api/docs" }

    describe "the maintenance banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(maintenance_text) }
      end

      context "when enabled" do
        let(:maintenance_banner) { true }

        it { expect(response.body).to include(maintenance_text) }
      end
    end

    describe "the incident banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(incident_text) }
      end

      context "when enabled" do
        let(:incident_banner) { true }

        it { expect(response.body).to include(incident_text) }
      end
    end
  end

  # No banners are displayed
  context "on the api_home layout" do
    let(:path) { "/api/docs/training/guidance" }

    describe "the maintenance banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(maintenance_text) }
      end

      context "when enabled" do
        let(:maintenance_banner) { true }

        it { expect(response.body).not_to include(maintenance_text) }
      end
    end

    describe "the incident banner" do
      context "when disabled" do
        it { expect(response.body).not_to include(incident_text) }
      end

      context "when enabled" do
        let(:incident_banner) { true }

        it { expect(response.body).not_to include(incident_text) }
      end
    end
  end
end
