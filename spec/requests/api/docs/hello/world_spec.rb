require "swagger_helper"

RSpec.describe "Hello world endpoint", openapi_spec: "hello/swagger.yaml", type: :request do
  document_api(get: "/api/hello/world") do
    described_as "Check you can call an open API endpoint"
    tagged_as "Hello world"

    responds_with 200, "A static greeting" do
      serialized_using API::Hello::WorldSerializer
    end

    responds_with 429, "Too many requests. Retry after the rate limit period has passed.", rack_attack: true do
      before do
        allow(Rack::Attack.cache).to receive(:store).and_return(ActiveSupport::Cache.lookup_store(:memory_store))
        allow(Rack::Attack.throttles["public API requests by ip"]).to receive(:limit).and_return(0)
      end
    end
  end
end
