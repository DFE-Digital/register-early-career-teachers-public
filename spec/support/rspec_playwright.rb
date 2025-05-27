require 'capybara'
require 'playwright'

module RSpecPlaywright
  class PlaywrightMajorVersionMismatch < StandardError; end

  DEFAULT_TIMEOUT = 30_000
  PLAYWRIGHT_CLI_EXECUTABLE_PATH = "./node_modules/.bin/playwright".freeze

  def self.start_browser
    Playwright.create(playwright_cli_executable_path: PLAYWRIGHT_CLI_EXECUTABLE_PATH)
              .playwright
              .chromium
              .launch(headless:)
  end

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

  def self.check_versions!
    ruby_playwright_version = Gem::Version
                                .new(Playwright::VERSION)
                                .segments
                                .first(2)
    javascript_playwright_version = File.read('package-lock.json')
                                        .match(%r{"playwright":\ "\^(?<version>.*)"})[:version]
                                        .then { |v| Gem::Version.new(v).segments }
                                        .first(2)

    fail(PlaywrightMajorVersionMismatch) unless ruby_playwright_version == javascript_playwright_version
  end
end
