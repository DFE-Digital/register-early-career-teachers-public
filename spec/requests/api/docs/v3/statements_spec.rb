require "swagger_helper"

RSpec.describe "Statements endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  path "api/v3/statements" do
    get "Retrieve financial statements" do
      tags "Statements"
      produces "application/json"

      response "401", "Unauthorized" do
        run_test!
      end
    end
  end
end
