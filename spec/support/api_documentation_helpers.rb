module APIDocumentationHelpers
  API_NAME_AND_VERSION = %r{\A/api/[^/]+(?:/v\d+)?/} # /api/<resource>/v<version>
  QUERY_PARAM = /\A\{[^}]+\}\z/ # {id}

  def document_api(request, &block)
    method, path = request.first
    operation_id = generate_operation_id(method, path)

    path(path) do
      public_send(method, nil) do
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

  def responds_with(status, description, **additional_options, &block)
    response(status.to_s, description, additional_options) do
      instance_exec(&block)

      run_test!
    end
  end

  def serialized_using(serializer, include_namespace: false)
    schema serializer.openapi_ref(include_namespace:)
  end

private

  def generate_operation_id(method, path)
    segments = operation_segments(path)
    action = named_action(segments) || method.to_s.downcase
    resources = segments.reject { it.match?(QUERY_PARAM) }.map(&:singularize)

    # GET collections retain the final resource's plural name.
    resources[-1] = segments.last if get_collection?(action, segments)

    "#{action}#{resources.map(&:camelize).join}"
  end

  def get_collection?(action, segments)
    action == "get" && !segments.last.match?(QUERY_PARAM)
  end

  # A path ending in a query parameter followed by a singular
  # string literal is treated as a named action, e.g. /{id}/void.
  def named_action(segments)
    return unless segments.last(2) in [QUERY_PARAM, String]
    return unless segments.last == segments.last.singularize

    segments.pop.camelize(:lower)
  end

  def operation_segments(path)
    path
      .remove(API_NAME_AND_VERSION)
      .split("/")
      .map(&:underscore)
  end
end
