RSpec.configure do |config|
  config.before(:each, :with_feature_flags) do |example|
    allow(Rails.application.config).to receive_messages(
      example.metadata.fetch(:with_feature_flags)
    )
  end
end
