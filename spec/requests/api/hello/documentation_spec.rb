RSpec.describe "GET /api/docs/hello", type: :request do
  it "shows the hello API documentation" do
    get "/api/docs/hello"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-version="hello"))
  end

  context "when the hello API is disabled" do
    before { allow(Rails.application.config).to receive(:enable_apis_under_development).and_return(false) }

    it "is not found" do
      get "/api/docs/hello"

      expect(response).to have_http_status(:not_found)
    end
  end
end
