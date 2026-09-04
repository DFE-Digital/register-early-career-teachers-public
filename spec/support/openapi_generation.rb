RSpec.configure do |config|
  config.after(:suite) do
    next unless ENV["GENERATE_OPENAPI"]

    OpenAPI::Writer.write
  end
end
