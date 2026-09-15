module APIDocumentationHelpers
  def document_api(request)
    method, path = request.first

    @api_documentation = {
      method:,
      path:,
      query_parameter_serializers: [],
      responses: [],
    }

    yield

    documentation = @api_documentation

    path documentation[:path] do
      public_send(documentation[:method], documentation[:description]) do
        tags documentation[:tag]

        consumes "application/json"
        produces "application/json"
        security [{ api_key: [] }]
        operationId "#{documentation[:method]}#{documentation[:tag].delete(' ')}"

        documentation[:query_parameter_serializers].each do |serializer|
          parameter(
            name: serializer.openapi_schema_name,
            in: :query,
            required: false,
            schema: serializer.openapi_ref
          )
        end

        documentation[:responses].each do |documented_response|
          response(
            documented_response[:status].to_s,
            documented_response[:description]
          ) do
            schema documented_response[:schema]

            run_test!
          end
        end
      end
    end
  end

  def described_as(description)
    @api_documentation[:description] = description
  end

  def tagged_as(tag)
    @api_documentation[:tag] = tag
  end

  def with_query_parameters_serialized_using(*serializers)
    @api_documentation[:query_parameter_serializers].concat(serializers)
  end

  def responds_with(status, description)
    @api_documentation_response = {}

    yield

    @api_documentation[:responses] << {
      status:,
      description:,
      schema: @api_documentation_response[:schema],
    }
  ensure
    @api_documentation_response = nil
  end

  def a_list_serialized_using(serializer)
    @api_documentation_response[:schema] = {
      type: :object,
      required: [:data],
      properties: {
        data: {
          type: :array,
          items: serializer.openapi_ref,
        },
      },
    }
  end
end
