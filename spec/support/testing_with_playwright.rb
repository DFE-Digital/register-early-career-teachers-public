require_relative "rspec_playwright"

# Directory for storing failure screenshots
SCREENSHOT_DIR = Rails.root.join("tmp/failure_screenshots")

RSpec.configure do |config|
  config.add_setting :playwright_browser
  config.add_setting :playwright_page
  config.add_setting :playwright_heading_hierarchy_recorder
  config.include_context "page", type: :feature

  # Ensure screenshot directory exists
  FileUtils.mkdir_p(SCREENSHOT_DIR) unless Dir.exist?(SCREENSHOT_DIR)

  config.before(:suite) do
    RSpecPlaywright.check_versions!
  end

  # Start/Reuse Playwright browser on every feature spec
  config.before(type: :feature) do
    config.playwright_browser ||= RSpecPlaywright.start_browser
    base_url = Capybara.current_session.server.base_url
    config.playwright_page = config.playwright_browser
                                   .new_page(baseURL: base_url,
                                             javaScriptEnabled: Capybara.current_driver == :js_enabled)
    config.playwright_page.set_default_timeout(RSpecPlaywright::DEFAULT_TIMEOUT)
    config.playwright_page.set_default_navigation_timeout(RSpecPlaywright::DEFAULT_NAVIGATION_TIMEOUT)
    config.playwright_heading_hierarchy_recorder = HeadingHierarchy::HARPageVisitRecorder.new(
      config.playwright_page,
      base_url:
    )
    config.playwright_heading_hierarchy_recorder.start
  end

  # Close Playwright page after each feature spec
  config.after(type: :feature) do |example|
    heading_hierarchy_failure = nil
    teardown_failure = nil

    begin
      page_visits = config.playwright_heading_hierarchy_recorder.stop

      if example.exception.nil?
        page_visits.each do |page_visit|
          expect(page_visit).to have_valid_heading_hierarchy
        rescue RSpec::Expectations::ExpectationNotMetError => e
          heading_hierarchy_failure = RSpec::Expectations::ExpectationNotMetError.new(
            "#{page_visit.url}\n#{e.message}"
          )
          break
        end
      end
    rescue StandardError => e
      teardown_failure = e
    ensure
      # Take screenshots on failure for feature tests
      if example.exception || heading_hierarchy_failure || teardown_failure
        begin
          # Generate a filename based on the test
          filename = "#{example.metadata[:file_path].gsub(/[^0-9A-Za-z]/, '_')}_line#{example.metadata[:line_number]}_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.png"
          screenshot_path = SCREENSHOT_DIR.join(filename)

          # Take screenshot if page is available
          if defined?(page) && page.respond_to?(:screenshot)
            page.screenshot(path: screenshot_path.to_s)
            puts "\nScreenshot saved to: #{screenshot_path}"
          end
        rescue StandardError => e
          puts "\nFailed to take screenshot: #{e.message}"
        end
      end

      begin
        page.close
      rescue StandardError => e
        teardown_failure ||= e
      end
    end

    raise heading_hierarchy_failure if heading_hierarchy_failure
    raise teardown_failure if teardown_failure && example.exception.nil?
  end

  # Close Playwright browser after the suite's finished
  config.after(:suite) do
    RSpecPlaywright.close_browser
  end
end
