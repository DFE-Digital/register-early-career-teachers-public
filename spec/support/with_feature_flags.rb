RSpec.configure do |config|
  config.around(:each, :with_feature_flags) do |example|
    original_values = {}
    feature_flags = example.metadata.fetch(:with_feature_flags)

    feature_flags.each do |k, v|
      original_values[k] = Rails.application.config.send(k)

      Rails.application.config.send("#{k}=", v)
    end

    example.run

    original_values.each do |k, v|
      Rails.application.config.send("#{k}=", v)
    end
  end
end
