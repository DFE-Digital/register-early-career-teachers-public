require_relative 'rspec_playwright'

RSpec.configure do |config|
  config.add_setting :playwright_browser
  config.add_setting :playwright_page
  config.include_context 'page', type: :feature

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
  end

  # Close Playwright page after each feature spec
  config.after(type: :feature) do
    page.close
  end

  # Close Playwright browser after the suite's finished
  config.after(:suite) do
    RSpecPlaywright.close_browser
  end
end
