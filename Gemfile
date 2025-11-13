source "https://rubygems.org"

ruby "3.4.7"

gem "rails", "~> 8.1.1"

gem "blazer"
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "csv"
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.9"
gem "dfe-wizard", github: "DFE-Digital/dfe-wizard"
gem "faraday"
gem "jsbundling-rails"
gem "pg", "~> 1.6"
gem "propshaft"
gem "puma", ">= 5.0"
gem "rack-attack"
gem "redis"
gem "tzinfo-data", platforms: %i[windows jruby]

gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "govuk_markdown"

gem "mail-notify"

gem "sentry-rails"
gem "sentry-ruby"
gem "stackprof"
gem "state_machines-activerecord"

# Background jobs
gem "mission_control-jobs"
gem "solid_queue"

# DfE Sign-In
gem "omniauth"
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection'

# OTP Sign-in
gem "base32"
gem "rotp"

# Fetching from APIs
gem "rubyzip"
gem "savon"

# Render smart quotes
gem 'rubypants'

# Batch progress bar
gem 'hotwire-rails'
gem 'turbo-rails'

# JSON Serializer
gem "blueprinter"
gem "oj"

gem "async-http-faraday"
gem "with_advisory_lock"

gem "diffy"

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "pg_query"
  gem 'prosopite'
end

group :test do
  gem "capybara"
  gem "playwright-ruby-client"
  gem "rspec"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "webmock"
end

group :development, :test do
  gem "brakeman"
  gem "debug", platforms: %i[mri windows]
  gem 'herb'
  gem 'rswag-specs'
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-govuk', require: false
  gem 'rubocop-performance', require: false
end

group :development, :test, :review, :staging, :sandbox do
  gem "factory_bot_rails"
  gem "faker"
end

group :nanoc do
  gem "asciidoctor"
  gem "nanoc"
  gem "nanoc-live"
  gem "webrick"
end
