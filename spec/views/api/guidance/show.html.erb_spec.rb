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
end
