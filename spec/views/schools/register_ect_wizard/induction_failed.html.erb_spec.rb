RSpec.describe "schools/register_ect_wizard/induction_failed.html.erb" do
  let(:ect) { double('ECT', full_name: 'John Doe') }

  before do
    assign(:ect, ect)
    render
  end

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql('You cannot register John Doe')
  end

  it "displays the ECT's full name in the body" do
    expect(rendered).to have_text("Our records show John Doe has failed their induction and is not eligible for further ECT training.")
  end

  it "includes a link to register another ECT" do
    expect(rendered).to have_link('Register another ECT', href: schools_register_ect_wizard_find_ect_path)
  end
end
