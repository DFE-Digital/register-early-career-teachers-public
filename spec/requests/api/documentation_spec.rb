RSpec.describe "API documentation", type: :request do
  subject { response }

  describe "GET /api/docs", with_feature_flags: { enable_apis_under_development: true } do
    before do
      get api_documentation_path
    end

    it { is_expected.to have_http_status(:ok) }

    it { expect(response.body).to include("Register early career teachers APIs") }

    it { expect(response.body).to include("Home") }
    it { expect(response.body).to include("Authorisation") }
    it { expect(response.body).to include("Induction API") }
    it { expect(response.body).to include(%(href="#{api_induction_v1_documentation_path}")) }
    it { expect(response.body).to include("Hello API") }
    it { expect(response.body).to include(%(href="#{api_hello_documentation_path}")) }

    context "when the training API feature flag is true", with_feature_flags: { enable_training_api: true } do
      it { expect(response.body).to include("Training API") }
      it { expect(response.body).to include(%(href="#{api_training_v4_documentation_path}")) }
    end

    context "when the training API feature flag is false", with_feature_flags: { enable_training_api: false } do
      it { expect(response.body).not_to include("Training API") }
      it { expect(response.body).not_to include(%(href="#{api_training_v4_documentation_path}")) }
    end

    context "when enable_apis_under_development is false", with_feature_flags: { enable_apis_under_development: false } do
      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
