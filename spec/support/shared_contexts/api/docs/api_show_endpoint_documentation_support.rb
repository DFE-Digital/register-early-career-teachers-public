RSpec.shared_context "an API show endpoint documentation", :exceptions_app do |url, tag, resource_description, response_schema_ref, mandatory_cohort_filter = nil|
  path url do
    get "Retrieve a single #{resource_description}" do
      tags tag
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      if mandatory_cohort_filter
        parameter name: "filter[cohort]",
                  example: "2024",
                  in: :query,
                  style: "deepObject",
                  required: true
        let(:"filter[cohort]") { school_partnership.contract_period.year }
      end

      response "200", "A single #{resource_description}" do
        let(:id) { resource.api_id }

        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { resource.api_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "404", "Not found" do
        let(:id) { SecureRandom.uuid }

        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end
end
