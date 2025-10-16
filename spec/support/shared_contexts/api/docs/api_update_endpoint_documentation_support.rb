RSpec.shared_context "an API update endpoint documentation", :exceptions_app do |options = {}|
  path options[:url] do
    put "Update a #{options[:resource_description]}" do
      tags options[:tag]
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
        in: :path,
        required: true,
        schema: {
          "$ref": "#/components/schemas/IDAttribute"
        }

      parameter name: :params,
        in: :body,
        style: :deepObject,
        required: false,
        schema: {
          "$ref": options[:request_schema_ref]
        }

      let(:id) { resource.api_id }

      response "200", "The updated #{options[:resource_description]}" do
        schema({"$ref": options[:response_schema_ref]})

        run_test!
      end

      response "401", "Unauthorized" do
        let(:token) { "invalid" }

        schema({"$ref": "#/components/schemas/UnauthorisedResponse"})

        run_test!
      end

      response "400", "Bad request" do
        let(:params) { {data: {}} }

        schema({"$ref": "#/components/schemas/BadRequestResponse"})

        run_test!
      end

      response "422", "Unprocessable entity" do
        let(:params) { invalid_params }

        schema({"$ref": "#/components/schemas/UnprocessableContentResponse"})

        run_test!
      end

      response "404", "Not found" do
        let(:id) { SecureRandom.uuid }

        schema({"$ref": "#/components/schemas/NotFoundResponse"})

        run_test!
      end
    end
  end
end
