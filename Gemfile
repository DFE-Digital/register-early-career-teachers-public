source "https://rubygems.org"

ruby "3.3.4"

gem "rails", "~> 8.0.2"

gem "blazer"
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "csv"
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.4"
gem "dfe-wizard", github: "DFE-Digital/dfe-wizard"
gem "jsbundling-rails"
gem "pg", "~> 1.5"
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
gem "solid_queue"
gem "stackprof"

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

# For the API
gem "blueprinter"
gem "oj"

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  gem "capybara"
  gem "playwright-ruby-client"
  gem "rspec"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "super_diff"
end

group :development, :test do
  gem "brakeman"
  gem "debug", platforms: %i[mri windows]
  gem "factory_bot_rails"
  gem "faker"
  gem 'rails-erd'
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-govuk', require: false
  gem 'rubocop-performance', require: false
end

group :nanoc do
  gem "asciidoctor"
  gem "nanoc"
  gem "nanoc-live"
  gem "webrick"
end
