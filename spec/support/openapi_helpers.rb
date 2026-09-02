require "json_schemer"

module OpenAPIHelpers
  def expect_response_to_match_open_api(endpoint:, status: response.status)
    schema = OpenAPI::SchemaResolver.resolve(
      endpoint.response_schema(status)
    )

    errors =
      JSONSchemer
        .schema(schema)
        .validate(response.parsed_body)
        .to_a

    expect(errors).to be_empty, -> {
      errors.map { |error|
        "#{error['data_pointer']}: #{error['type']}"
      }.join("\n")
    }
  end

  def capture_open_api_response_example(endpoint:, status:, example:)
    OpenAPI::Examples.register(
      endpoint:,
      status:,
      example:
    )
  end
end

RSpec.configure do |config|
  config.include OpenAPIHelpers, type: :request
end
