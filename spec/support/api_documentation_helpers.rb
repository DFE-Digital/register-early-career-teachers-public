module APIDocumentationHelpers
  def document_api(request, &block)
    verb, path = request.first
    operation_id = "#{verb}#{path.split(%r{[/-]}).compact_blank.map(&:camelize).join}"

    path(path) do
      public_send(verb, nil) do
        produces "application/json"
        operationId operation_id
        security []

        instance_exec(&block)
      end
    end
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

  def responds_with(status, description, &block)
    response(status.to_s, description) do
      instance_exec(&block)

      run_test!
    end
  end

  def serialized_using(serializer)
    schema serializer.openapi_ref
  end
end
