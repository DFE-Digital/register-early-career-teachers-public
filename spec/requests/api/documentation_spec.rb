RSpec.describe "API documentation", type: :request do
  subject { response }

  describe "GET /api/docs" do
    before do
      allow(Rails.application.config)
        .to receive(:enable_apis_under_development) { enable_apis_under_development }

      get api_documentation_path
    end

    let(:enable_apis_under_development) { true }

    it { is_expected.to have_http_status(:ok) }

    it { expect(response.body).to include("Register early career teachers APIs") }

    it { expect(response.body).to include("Home") }
    it { expect(response.body).to include("Authentication") }
    it { expect(response.body).to include("Training API") }
    it { expect(response.body).to include("Induction API") }
    it { expect(response.body).to include("Hello World API") }

    context "when enable_apis_under_development is false" do
      let(:enable_apis_under_development) { false }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
