require_relative 'rspec_playwright'

RSpec.configure do |config|
  config.add_setting :playwright_browser
  config.add_setting :playwright_page

  # Start/Reuse Playwright browser
  config.before(type: :feature) do
    config.playwright_browser ||= RSpecPlaywright.start_browser
    config.playwright_page = config.playwright_browser
                                   .new_page(baseURL: Capybara.current_session.server.base_url,
                                             javaScriptEnabled: Capybara.current_driver == :js_enabled)
    config.playwright_page.set_default_timeout(RSpecPlaywright::DEFAULT_TIMEOUT)
  end

  # Close Playwright browsers
  config.after(:suite) do
    RSpecPlaywright.close_browser
  end
end
