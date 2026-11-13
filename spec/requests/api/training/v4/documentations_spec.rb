RSpec.describe "GET /api/docs/training/v4", type: :request, with_feature_flags: { enable_training_api: true } do
  it "shows the training API v4 documentation" do
    get "/api/docs/training/v4"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-url="/api/docs/training/v4/swagger.yaml"))
  end

  context "when the API is disabled", with_feature_flags: { enable_training_api: false } do
    it "is not found" do
      get "/api/docs/training/v4"

      expect(response).to have_http_status(:not_found)
    end
  end
end
