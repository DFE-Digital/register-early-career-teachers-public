RSpec.describe "Errors", type: :request do
  before do
    allow(Rails.application).to receive(:env_config).and_wrap_original do
      it.call.merge(
        "action_dispatch.show_exceptions" => true,
        "action_dispatch.show_detailed_exceptions" => false,
        "consider_all_requests_local" => false
      )
    end
  end

  context "when requesting a path that does not exist" do
    it "returns 404 not found" do
      get "/path/not/found"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
    end
  end

  context "when an unexpected error is raised" do
    it "returns 500 internal server error" do
      allow(PagesController).to receive(:new).and_raise(StandardError.new)

      get root_path

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Sorry, there’s a problem with the service")
    end
  end

  context "when an unprocessable content error is raised" do
    it "returns 422 unprocessable entity" do
      allow(PagesController).to receive(:new).and_raise(ActionController::InvalidAuthenticityToken.new)

      get root_path

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Sorry, there’s a problem with the service")
    end
  end

  context "when a rate limit is breached", :rack_attack do
    it "returns 429 too many requests" do
      memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
      allow(Rack::Attack.cache).to receive(:store) { memory_store }

      throttle = Rack::Attack.throttles["All other requests by ip"]
      allow(throttle).to receive(:limit).and_return(0)

      get root_path

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")
    end
  end
end
