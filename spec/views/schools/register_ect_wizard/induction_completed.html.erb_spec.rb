RSpec.describe "schools/register_ect_wizard/induction_exempt.html.erb" do
  let(:ect) { double('ECT', full_name: 'John Doe') }

  before do
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql('You cannot register John Doe')
  end

  it "displays the ECT's full name in the body" do
    render
    expect(rendered).to have_text("Our records show John Doe is exempt from having to serve induction and therefore cannot be registered as an ECT.")
  end

  it "includes a link to register another ECT" do
    render
    expect(rendered).to have_link('Register another ECT', href: schools_register_ect_wizard_find_ect_path)
  end
end
