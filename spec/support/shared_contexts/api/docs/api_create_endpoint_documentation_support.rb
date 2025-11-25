RSpec.shared_context "an API create endpoint documentation", :exceptions_app do |params = {}|
  path params[:url] do
    post params[:resource_description] do
      tags params[:tag]
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: false,
                schema: {
                  "$ref": params[:request_schema_ref],
                }

      response "200", params[:response_description] do
        schema({ "$ref": params[:response_schema_ref] })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "400", "Bad request" do
        let(:params) { { data: {} } }

        schema({ "$ref": "#/components/schemas/BadRequestResponse" })

        run_test!
      end

      response "422", "Unprocessable entity" do
        let(:params) { invalid_params }

        schema({ "$ref": "#/components/schemas/UnprocessableContentResponse" })

        run_test!
      end
    end
  end
end
