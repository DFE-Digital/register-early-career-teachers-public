require 'ostruct'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }
Rails.application.load_tasks

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.include ActiveSupport::Testing::TimeHelpers
  config.include Features::ViewHelpers, type: :feature
  config.include APIHelper, type: :request
  config.include HaveSummaryListRow, type: :component

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:each, :enable_schools_interface) do
    allow(Rails.application.config)
      .to receive(:enable_schools_interface)
      .and_return(true)
  end

  config.around do |example|
    declarative_updates_to_skip = %i[metadata touch]

    declarative_updates_to_skip.delete(:metadata) if example.metadata[:with_metadata]
    declarative_updates_to_skip.delete(:touch) if example.metadata[:with_touches]

    if declarative_updates_to_skip.empty?
      example.run
    else
      DeclarativeUpdates.skip(*declarative_updates_to_skip) { example.run }
    end
  end
end
