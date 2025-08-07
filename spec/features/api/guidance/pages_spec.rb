RSpec.describe "Guidance pages" do
  scenario "Viewing page 'Guidance for lead providers'" do
    given_i_am_on_the_api_guidance_page
    when_i_click_guidance
    then_i_should_see_guidance_page
    and_i_see_sidebar_menu
  end

  scenario "Viewing page 'Release notes'" do
    given_i_am_on_the_api_guidance_page
    when_i_click_release_notes
    then_i_should_see_release_notes_page
    and_i_do_not_see_sidebar_menu
  end

private

  def given_i_am_on_the_api_guidance_page
    path = '/api/guidance'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_click_guidance
    page.get_by_role('link', name: 'Guidance', exact: true).click
    expect(page.url).to end_with('/api/guidance/guidance-for-lead-providers')
  end

  def when_i_click_release_notes
    page.get_by_role('link', name: 'Release notes', exact: true).click
    expect(page.url).to end_with('/api/guidance/release-notes')
  end

  def then_i_should_see_guidance_page
    expect(page.get_by_role("heading", name: "Guidance for lead providers")).to be_visible
  end

  def then_i_should_see_release_notes_page
    expect(page.get_by_role("heading", name: "Release notes")).to be_visible
  end

  def and_i_see_sidebar_menu
    sidebar = page.locator("nav.x-govuk-sub-navigation")
    expect(sidebar.get_by_role("link", name: "API IDs explained")).to be_visible
    expect(sidebar.get_by_role("link", name: "API data states")).to be_visible
  end

  def and_i_do_not_see_sidebar_menu
    sidebar = page.locator("nav.x-govuk-sub-navigation")
    expect(sidebar.get_by_role("link", name: "API IDs explained")).not_to be_visible
  end
end
