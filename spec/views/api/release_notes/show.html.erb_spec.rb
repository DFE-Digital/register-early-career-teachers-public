RSpec.describe "api/release_notes/show.html.erb" do
  let(:release_note) { { title: "Note 1", date: 1.month.ago, body: "Note 1 body", tags: %w[bug-fix new-feature] } }

  before do
    assign(:release_note, API::ReleaseNote.new(**release_note))
    render
  end

  it "shows the correct title" do
    expect(view.content_for(:page_title)).to have_text(release_note[:title])
  end

  it "shows the correct heading" do
    expect(view.content_for(:page_header)).to have_text(release_note[:title])
  end

  it "shows the correct caption" do
    expect(view.content_for(:page_caption)).to have_text(release_note[:date].to_formatted_s(:govuk))
  end

  it "displays the release note body" do
    expect(rendered).to have_css("p", text: release_note[:body])

    expect(rendered).to have_css(".tag-group .govuk-tag--green", text: "New feature")
    expect(rendered).to have_css(".tag-group .govuk-tag--yellow", text: "Bug fix")
  end
end
