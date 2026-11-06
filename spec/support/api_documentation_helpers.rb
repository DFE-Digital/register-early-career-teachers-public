module APIDocumentationHelpers
  def document_api(request, &block)
    verb, path = request.first

    path(path) do
      public_send(verb, nil) do
        produces "application/json"
        security []

        instance_exec(&block)
        ensure_required_metadata!
      end
    end
  end

  def identified_as(identifier)
    operationId identifier
  end

  def described_as(summary)
    metadata[:operation][:summary] = summary
  end

  def tagged_as(tag)
    tags tag
  end

  def secured_by(scheme)
    security [{ scheme => [] }]
  end

  def responds_with(status, description, **additional_options, &block)
    response(status.to_s, description, additional_options) do
      instance_exec(&block)

      run_test!
    end
  end

  def request_body_using(request)
    parameter name: request.param_key, in: :body, schema: request.openapi_ref
  end

  def serialized_using(serializer, include_namespace: false)
    schema serializer.openapi_ref(include_namespace:)
  end

private

  def ensure_required_metadata!
    operation = metadata[:operation] || {}

    missing = {
      described_as: operation[:summary],
      tagged_as: operation[:tags],
      identified_as: operation[:operationId]
    }.filter_map { |helper, value| helper if value.blank? }

    return if missing.empty?

    raise ArgumentError, "API documentation must specify #{missing.join(', ')}"
  end
end
