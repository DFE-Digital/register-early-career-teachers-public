RSpec::Matchers.define :have_documented_api_error do |attribute, message = nil, context = nil|
  match do |actual|
    RSpec.configuration.api_error_documentation.add_error(
      example: RSpec.current_example,
      service: actual.class,
      attribute:,
      message:
    )

    @error_matcher = have_error(attribute, message, context)
    @error_matcher.matches?(actual)
  end

  failure_message do
    @error_matcher.failure_message
  end
end
