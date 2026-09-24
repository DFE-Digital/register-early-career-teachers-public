RSpec.describe "GET /api/hello/world", type: :request do
  it "says hello" do
    get "/api/hello/world"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("message" => "Hello World")
  end

  context "when the hello API is disabled" do
    around do |example|
      Rails.application.config.enable_apis_under_development = false
      example.run
    ensure
      Rails.application.config.enable_apis_under_development = true
    end

    it "is not found" do
      get "/api/hello/world"

      expect(response).to have_http_status(:not_found)
    end
  end
end
