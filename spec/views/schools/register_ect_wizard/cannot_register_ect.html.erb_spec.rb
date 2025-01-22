RSpec.describe "schools/register_ect_wizard/cannot_register_ect" do
  let(:ect) { double('ECT', full_name: 'John Doe') }
  let(:title) { "You cannot register #{ect.full_name}" }

  before do
    assign(:ect, ect)
    render
  end

  it "sets the page title to 'You cannot register John Doe'" do
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "displays the cannot register ECT message" do
    expect(rendered).to have_content("Our records show that John Doe cannot be registered for training or mentoring.")
  end

  it "includes a link back to ECTs" do
    expect(rendered).to have_link("Back to ECTs", href: schools_ects_home_path)
  end
end
