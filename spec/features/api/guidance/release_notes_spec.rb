RSpec.describe "Release notes" do
  let(:release_notes) do
    YAML.load_file(
      Rails.root.join("app/views/api/release_notes/release_notes.yml"),
      permitted_classes: [Date]
    ).map { API::ReleaseNote.new(**it.symbolize_keys) }
  end
  let(:release_note_2) { release_notes[2] }

  scenario "Displaying all the release notes" do
    given_i_am_on_the_api_guidance_page
    when_i_click_release_notes
    then_i_should_see_an_entry_for_each_release_note
  end

  scenario "Viewing a release note" do
    given_i_am_on_the_api_guidance_page
    when_i_click_release_notes
    and_i_click_on_a_release_note
    then_i_should_see_the_release_note
  end

  scenario "Page not found" do
    when_i_visit_non_existing_release_note_page
    then_i_should_see_not_found
  end

private

  def given_i_am_on_the_api_guidance_page
    path = "/api/guidance"
    page.goto(path)
    expect(page).to have_path(path)
  end

  def when_i_click_release_notes
    page.get_by_role("link", name: "Release notes", exact: true).click
    expect(page).to have_path("/api/guidance/release-notes")
  end

  def then_i_should_see_an_entry_for_each_release_note
    release_notes.each do |note|
      expect(page.locator("h2", hasText: note.title)).to be_visible
    end
  end

  def when_i_visit_non_existing_release_note_page
    path = api_guidance_release_note_path("does-not-exist")
    page.goto(path)
    expect(page).to have_path(path)
  end

  def then_i_should_see_not_found
    expect(page.get_by_role("heading", name: "Page not found")).to be_visible
  end

  def and_i_click_on_a_release_note
    page.get_by_role("link", name: release_note_2.title, exact: true).click
    expect(page).to have_path("/api/guidance/release-notes/#{release_note_2.slug}")
  end

  def then_i_should_see_the_release_note
    expect(page.get_by_role("heading", name: release_note_2.title)).to be_visible
    expect(page.locator("span", hasText: release_note_2.date)).to be_visible
  end
end
