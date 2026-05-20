RSpec.describe "schools/registration_window_closed/show" do
  before do
    assign(:reopens_on, "15 June")
    render
  end

  it "sets the page title with the reopening date" do
    expect(sanitize(view.content_for(:page_title))).to eql(
      "You cannot register early career teachers (ECTs) or mentors until 15 June"
    )
  end

  it "shows the reopening date in the body" do
    expect(rendered).to have_content("Until 15 June you cannot:")
  end

  it "includes a back link to the ECT list" do
    expect(rendered).to have_link("Back to ECTs", href: schools_ects_home_path)
  end
end
