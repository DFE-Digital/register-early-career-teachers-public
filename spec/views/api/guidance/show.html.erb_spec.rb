RSpec.describe "api/guidance/show.html.erb" do
  it "shows the correct title" do
    render

    title_text = "API guidance"
    expect(view.content_for(:page_title)).to have_text(title_text)
  end

  it "shows the correct heading" do
    render

    header_text = "Lead provider guidance: early career training programme"
    expect(view.content_for(:page_header)).to have_text(header_text)
  end

  context "when a release note is present" do
    let(:release_note_data) do
      YAML.load_file(
        Rails.root.join("app/views/api/guidance/release_notes.yml"),
        permitted_classes: [Date]
      ).map { |note| API::ReleaseNote.new(**note.symbolize_keys) }
    end
    let!(:release_note) { release_note_data.first }

    it "displays the latest release note summary" do
      assign(:latest_release_note, release_note)

      render

      expect(rendered).to have_text(release_note.date.to_s)
      expect(rendered).to have_text(release_note.title)
      expect(rendered).to have_text(release_note.tags.first.titleize.humanize)
      expect(rendered).to have_text(release_note.tags.last.titleize.humanize)
    end
  end
end
