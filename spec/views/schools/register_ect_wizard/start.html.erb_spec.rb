RSpec.describe "schools/register_ect_wizard/start.html.erb" do
  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("What you'll need to register a new ECT")
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_link('Continue', href: schools_register_ect_wizard_find_ect_path)
  end
end
