require "swagger_helper"

RSpec.describe "Hello world endpoint", openapi_spec: "hello/swagger.yaml", type: :request do
  document_api(get: "/api/hello/world") do
    described_as "Check you can call an open API endpoint"
    tagged_as "Hello world"

    responds_with 200, "A static greeting" do
      serialized_using API::Hello::WorldSerializer
    end
  end
end
