require 'capybara'
require 'playwright'

module RSpecPlaywright
  DEFAULT_TIMEOUT = 3_000
  PLAYWRIGHT_CLI_EXECUTABLE_PATH = "./node_modules/.bin/playwright".freeze

  # rubocop:disable Rails/SaveBang
  def self.start_browser
    Playwright.create(playwright_cli_executable_path: PLAYWRIGHT_CLI_EXECUTABLE_PATH)
              .playwright
              .chromium
              .launch(headless:)
  end
  # rubocop:enable Rails/SaveBang

  def self.close_browser
    RSpec.configuration.playwright_browser&.close
    RSpec.configuration.playwright_browser = nil
    RSpec.configuration.playwright_page = nil
  end

  def self.headless
    ENV.fetch('HEADLESS', true).then do |value|
      return true if value.in?([true, '1', 'yes', 'true'])
      return false if value.in?([false, '0', 'no', 'false'])

      fail(ArgumentError, 'Invalid headless option')
    end
  end
end
