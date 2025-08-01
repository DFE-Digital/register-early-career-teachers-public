require "capybara/rspec"
require "view_component/test_helpers"
require "view_component/system_test_helpers"
require 'playwright'
require 'playwright/test'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.include Playwright::Test::Matchers, type: :feature
  # FactoryBot::Syntax::Methods deliberately omitted to avoid confusion with AR's `create`/`build`.

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
end

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_job, :have_enqueued_job
WebMock.disable_net_connect!(allow_localhost: true)
