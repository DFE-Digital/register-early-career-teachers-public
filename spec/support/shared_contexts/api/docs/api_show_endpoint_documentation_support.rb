RSpec.shared_context "an API show endpoint documentation", :exceptions_app do |params = {}|
  path params[:url] do
    get "Retrieve a single #{params[:resource_description]}" do
      tags params[:tag]
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      if params[:filter_schema_ref]
        parameter name: :filter,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": params[:filter_schema_ref],
                  },
                  style: "deepObject"
      end

      response "200", "A single #{params[:resource_description]}" do
        let(:id) { resource.api_id }

        schema({ "$ref": params[:response_schema_ref] })

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
