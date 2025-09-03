# Playwright equivalent of Capybara's have_current_path matcher.
#
# @example
#   expect(page).to have_path('/expected/path')
#
# @param page [Playwright::Page]
# @param path [String]
RSpec::Matchers.define :have_path do |path|
  match do |_page|
    current_path == path
  end

  failure_message do |_page|
    "expected '#{current_path}' to equal '#{path}'"
  end

  description do
    "have the path '#{current_path}'"
  end

  def current_path
    URI.parse(page.url).path
  end
end
