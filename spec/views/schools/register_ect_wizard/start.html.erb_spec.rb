RSpec.describe "schools/register_ect_wizard/start.html.erb" do
  before do
    render
  end

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql("What you’ll need to register a new ECT")
  end

  it "sets the back link path" do
    expect(view.content_for(:backlink_or_breadcrumb)).to include(schools_ects_home_path)
  end

  it 'includes a continue button' do
    expect(rendered).to have_link('Continue', href: schools_register_ect_wizard_find_ect_path)
  end
end
