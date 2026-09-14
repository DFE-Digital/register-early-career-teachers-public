RSpec.shared_context "an open API index endpoint documentation", :exceptions_app do |params = {}|
  path params[:url] do
    get params[:resource_description] do
      tags params[:tag]
      consumes "application/json"
      produces "application/json"
      security [{ api_key: [] }]
      operationId params[:operation_id] || "get#{params[:tag].delete(' ')}"

      Array(params[:parameter_schemas]).each do |schema|
        parameter name: schema.openapi_schema_name,
                  in: :query,
                  required: false,
                  schema: schema.openapi_ref
      end

      response "200", params[:response_description] do
        schema(
          type: :object,
          required: [:data],
          properties: {
            data: {
              type: :array,
              items: params[:response_schema].openapi_ref,
            },
          }
        )

        run_test!
      end
    end
  end
end
