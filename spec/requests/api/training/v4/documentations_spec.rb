RSpec.describe "GET /api/docs/training/v4", type: :request do
  it "shows the training API v4 documentation" do
    get "/api/docs/training/v4"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-url="/api/docs/training/v4/swagger.yaml"))
  end

  context "when the API is disabled" do
    before { allow(Rails.application.config).to receive(:enable_apis_under_development).and_return(false) }

    it "is not found" do
      get "/api/docs/training/v4"

      expect(response).to have_http_status(:not_found)
    end
  end
end
