RSpec.describe "GET /api/docs/induction/v1", type: :request do
  it "shows the induction API documentation" do
    get "/api/docs/induction/v1"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-url="/api/docs/induction/v1/swagger.yaml"))
  end

  context "when the induction API is disabled" do
    before { allow(Rails.application.config).to receive(:enable_apis_under_development).and_return(false) }

    it "is not found" do
      get "/api/docs/induction/v1"

      expect(response).to have_http_status(:not_found)
    end
  end
end
