require "capybara"
require "playwright"

module RSpecPlaywright
  class PlaywrightMajorVersionMismatch < StandardError; end

  DEFAULT_TIMEOUT = 3_000
  DEFAULT_NAVIGATION_TIMEOUT = 10_000
  PLAYWRIGHT_CLI_EXECUTABLE_PATH = "./node_modules/.bin/playwright"

  def self.start_browser
    Playwright.create(playwright_cli_executable_path: PLAYWRIGHT_CLI_EXECUTABLE_PATH)
              .playwright
              .chromium
              .launch(headless:, slowMo:)
  end

  PAGE_SCREENSHOT_DIR = Rails.root.join("tmp/page_screenshots")
  ID_SEGMENT = /\A(\d+|\h{8}-\h{4}-\h{4}-\h{4}-\h{12})\z/
  YEAR_SEGMENT = /\A20\d\d\z/

  # Saves one screenshot per page path (ids become "_id_", query string ignored); never overwrites.
  def self.save_page_screenshot(page)
    segments = URI(page.url).path.split("/").compact_blank.map do |segment|
      segment.match?(ID_SEGMENT) && !segment.match?(YEAR_SEGMENT) ? "_id_" : segment
    end
    file = PAGE_SCREENSHOT_DIR.join("#{segments.join('/').presence || 'index'}.png")
    return if file.exist?

    FileUtils.mkdir_p(file.dirname)
    page.screenshot(path: file.to_s)
  rescue Playwright::Error
    nil # the page may have navigated or closed mid-capture
  end

  def self.close_browser
    RSpec.configuration.playwright_browser&.close
    RSpec.configuration.playwright_browser = nil
    RSpec.configuration.playwright_page = nil
  end

  def self.headless
    ENV.fetch("HEADLESS", true).then do |value|
      return true if value.in?([true, "1", "yes", "true"])
      return false if value.in?([false, "0", "no", "false"])

      fail(ArgumentError, "Invalid headless option")
    end
  end

  # rubocop:disable Naming/MethodName
  def self.slowMo
    ENV.fetch("SLOWMO", 0).to_i
  end
  # rubocop:enable Naming/MethodName

  def self.check_versions!
    ruby_playwright_version = Gem::Version
                                .new(Playwright::VERSION)
                                .segments
                                .first(2)
    javascript_playwright_version = File.read("package-lock.json")
                                        .match(%r{"playwright":\ "\^(?<version>.*)"})[:version]
                                        .then { |v| Gem::Version.new(v).segments }
                                        .first(2)

    fail(PlaywrightMajorVersionMismatch) unless ruby_playwright_version == javascript_playwright_version
  end
end
