RSpec.describe "api/guidance/release_notes.html.erb" do
  let(:release_note_1) { { title: 'Note 1', date: 1.month.ago, body: 'Note 1 body' } }
  let(:release_note_2) { { title: 'Note 2', date: 2.weeks.ago, body: 'Note 2 body' } }

  before do
    assign(:release_notes, [API::ReleaseNote.new(**release_note_1), API::ReleaseNote.new(**release_note_2)])
    render
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

      expect(rendered).to have_css('p', text: release_note_1[:body])
      expect(rendered).to have_css('p', text: release_note_2[:body])
    end
  end
end
