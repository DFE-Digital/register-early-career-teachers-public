RSpec.describe 'Viewing the release notes' do
  let(:release_note_data) do
    YAML.load_file(
      Rails.root.join('app/views/api/guidance/release_notes.yml'),
      permitted_classes: [Date]
    ).map { |note| API::ReleaseNote.new(**note.symbolize_keys) }
  end

  scenario 'Displaying all the release notes' do
    given_i_am_on_the_api_guidance_page
    when_i_click_release_notes
    then_i_should_see_an_entry_for_each_release_note
  end

private

  def given_i_am_on_the_api_guidance_page
    path = '/api/guidance'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_click_release_notes
    page.get_by_role('link', name: 'Release notes', exact: true).click
    expect(page.url).to end_with('/api/guidance/release-notes')
  end

  def then_i_should_see_an_entry_for_each_release_note
    release_note_data.map(&:title).each do |title|
      expect(page.get_by_role("heading", name: title)).to be_visible
    end
  end
end
