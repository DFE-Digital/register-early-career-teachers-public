RSpec.describe "api/release_notes/index.html.erb" do
  let(:release_note_1) { { title: 'Note 1', date: 1.month.ago, body: 'Note 1 body', tags: %w[bug-fix new-feature] } }
  let(:release_note_2) { { title: 'Note 2', date: 2.weeks.ago, body: 'Note 2 body', tags: %w[breaking-change sandbox-release] } }
  let(:release_notes) { [API::ReleaseNote.new(**release_note_1), API::ReleaseNote.new(**release_note_2)] }

  before do
    render locals: { release_notes: }
  end

  it 'shows the correct title' do
    title_text = 'Release notes'
    expect(view.content_for(:page_title)).to have_text(title_text)
  end

  it 'shows the correct heading' do
    header_text = 'Release notes'
    expect(view.content_for(:page_header)).to have_text(header_text)
  end

  it 'displays the list of release notes' do
    aggregate_failures do
      expect(rendered).to have_css('h2', text: release_note_1[:title])
      expect(rendered).to have_css('h2', text: release_note_2[:title])

      expect(rendered).to have_css('.govuk-caption-m', text: release_note_1[:date].to_formatted_s(:govuk))
      expect(rendered).to have_css('.govuk-caption-m', text: release_note_2[:date].to_formatted_s(:govuk))

      expect(rendered).to have_css('.tag-group .govuk-tag--green', text: "New feature")
      expect(rendered).to have_css('.tag-group .govuk-tag--yellow', text: "Bug fix")
      expect(rendered).to have_css('.tag-group .govuk-tag--red', text: "Breaking change")
      expect(rendered).to have_css('.tag-group .govuk-tag--grey', text: "Sandbox release")
    end
  end
end
