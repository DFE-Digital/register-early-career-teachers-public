require_relative "rspec_playwright"

# Directory for storing failure screenshots
SCREENSHOT_DIR = Rails.root.join("tmp/failure_screenshots")

RSpec.configure do |config|
  config.add_setting :playwright_browser
  config.add_setting :playwright_page
  config.include_context "page", type: :feature

  # Ensure screenshot directory exists
  FileUtils.mkdir_p(SCREENSHOT_DIR) unless Dir.exist?(SCREENSHOT_DIR)

  config.before(:suite) do
    RSpecPlaywright.check_versions!
  end

  # Start/Reuse Playwright browser on every feature spec
  config.before(type: :feature) do
    config.playwright_browser ||= RSpecPlaywright.start_browser
    config.playwright_page = config.playwright_browser
                                   .new_page(baseURL: Capybara.current_session.server.base_url,
                                             javaScriptEnabled: Capybara.current_driver == :js_enabled)
    config.playwright_page.set_default_timeout(RSpecPlaywright::DEFAULT_TIMEOUT)
    config.playwright_page.set_default_navigation_timeout(RSpecPlaywright::DEFAULT_NAVIGATION_TIMEOUT)
  end

  # Close Playwright page after each feature spec
  config.after(type: :feature) do |example|
    heading_hierarchy_failure = nil

    if example.exception.nil? && !page.closed?
      begin
        expect(page).to have_valid_heading_hierarchy
      rescue RSpec::Expectations::ExpectationNotMetError => e
        heading_hierarchy_failure = e
      end
    end

    # Take screenshots on failure for feature tests
    if example.exception || heading_hierarchy_failure
      # Generate a filename based on the test
      filename = "#{example.metadata[:file_path].gsub(/[^0-9A-Za-z]/, '_')}_line#{example.metadata[:line_number]}_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.png"
      screenshot_path = SCREENSHOT_DIR.join(filename)

      # Take screenshot if page is available
      if defined?(page) && page.respond_to?(:screenshot)
        begin
          page.screenshot(path: screenshot_path.to_s)
          puts "\nScreenshot saved to: #{screenshot_path}"
        rescue StandardError => e
          puts "\nFailed to take screenshot: #{e.message}"
        end
      end
    end

    page.close

    raise heading_hierarchy_failure if heading_hierarchy_failure
  end

  # Close Playwright browser after the suite's finished
  config.after(:suite) do
    RSpecPlaywright.close_browser
  end
end
