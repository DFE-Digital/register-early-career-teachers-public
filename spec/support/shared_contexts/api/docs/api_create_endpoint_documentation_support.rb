RSpec.shared_context "an API create endpoint documentation", :exceptions_app do |options = {}|
  path options[:url] do
    post "Create a #{options[:resource_description]}" do
      tags options[:tag]
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :params,
        in: :body,
        style: :deepObject,
        required: false,
        schema: {
          "$ref": options[:request_schema_ref]
        }

      response "200", "The created #{options[:resource_description]}" do
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
    end
  end
end
