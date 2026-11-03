module APIDocumentationHelpers
  def document_api(request, &block)
    verb, path = request.first

    path(path) do
      public_send(verb, nil) do
        produces "application/json"
        security []

        instance_exec(&block)
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

  def serialized_using(serializer, include_namespace: false)
    schema serializer.openapi_ref(include_namespace:)
  end
end
