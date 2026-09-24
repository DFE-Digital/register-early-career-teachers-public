RSpec.describe "GET /api/hello/world", type: :request do
  it "says hello" do
    get "/api/hello/world"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("message" => "Hello World")
  end

  context "when the hello API is disabled" do
    before { allow(Rails.application.config).to receive(:enable_apis_under_development).and_return(false) }

    it "is not found" do
      get "/api/hello/world"

      expect(response).to have_http_status(:not_found)
    end
  end
end
