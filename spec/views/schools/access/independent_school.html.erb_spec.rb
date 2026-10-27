RSpec.describe "schools/access/independent_school" do
  before do
    assign(:school_name, "Abbeymead Independent School")
    render
  end

  it "sets the page title with the school name" do
    expect(sanitize(view.content_for(:page_title))).to eql(
      "You cannot use Register early career teachers for Abbeymead Independent School"
    )
  end

  it "explains why the school cannot use the service" do
    expect(rendered).to have_content("Abbeymead Independent School is an independent school.")
  end

  it "links to guidance on training options" do
    expect(rendered).to have_link(
      "Find out about training options for early career teachers",
      href: "https://www.gov.uk/guidance/set-up-and-manage-the-early-career-teacher-entitlement"
    )
  end

  it "links to the support email address" do
    expect(rendered).to have_link(
      "continuing-professional-development@digital.education.gov.uk",
      href: "mailto:continuing-professional-development@digital.education.gov.uk"
    )
  end
end
