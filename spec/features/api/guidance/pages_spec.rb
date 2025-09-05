RSpec.describe "Guidance pages" do
  let(:latest_release_note) do
    notes = YAML.load_file(
      Rails.root.join("app/views/api/release_notes/release_notes.yml"),
      permitted_classes: [Date]
    )
    API::ReleaseNote.new(**notes.first.symbolize_keys)
  end

  scenario "Viewing page 'Guidance for lead providers'" do
    given_i_am_on_the_api_guidance_page
    when_i_click_guidance
    then_i_should_see_guidance_page
    and_i_see_sidebar_menu
  end

  scenario "Viewing all release notes" do
    given_i_am_on_the_api_guidance_page
    when_i_click_view_all_release_notes
    then_i_should_see_release_notes_page
    and_i_do_not_see_sidebar_menu
  end

  scenario "Viewing latest release note" do
    given_i_am_on_the_api_guidance_page
    when_i_click_on_the_latest_release_note
    then_i_should_go_to_the_latest_release_note
  end

  scenario "Page not found" do
    when_i_visit_non_existing_guidance_page
    then_i_should_see_not_found
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

  def when_i_click_view_all_release_notes
    page.get_by_role('link', name: 'View all release notes', exact: true).click
    expect(page.url).to end_with('/api/guidance/release-notes')
  end

  def when_i_click_on_the_latest_release_note
    page.get_by_role('link', name: latest_release_note.title, exact: true).click
  end

  def then_i_should_see_guidance_page
    expect(page.get_by_role("heading", name: "Guidance for lead providers")).to be_visible
  end

  def then_i_should_see_release_notes_page
    expect(page.get_by_role("heading", name: "Release notes")).to be_visible
  end

  def then_i_should_go_to_the_latest_release_note
    expect(page.url).to end_with("/api/guidance/release-notes/#{latest_release_note.slug}")
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

  def when_i_visit_non_existing_guidance_page
    path = api_guidance_page_path("does-not-exist")
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def then_i_should_see_not_found
    expect(page.get_by_role("heading", name: "Page not found")).to be_visible
  end
end
