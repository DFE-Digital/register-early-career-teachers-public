require 'timeout'

return unless Rails.application.config.enable_request_specs_timeout

RSpec.configure do |config|
  # Set a timeout for request specs
  config.add_setting :request_timeout, default: 3

  # Set a timeout for each request spec
  config.around(:each, type: :request) do |example|
    Timeout.timeout(config.request_timeout) do
      example.run
    end
  rescue Timeout::Error
    example.example.set_exception(Timeout::Error.new("Example timed out after #{config.request_timeout} seconds"))
    raise
  end
end
