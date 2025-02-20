RSpec.describe "schools/register_mentor_wizard/cannot_register_mentor" do
  let(:mentor) { double('Mentor', full_name: 'Jane Smith') }
  let(:title) {}

  before do
    assign(:mentor, mentor)
    render
  end

  context 'page title' do
    it { expect(sanitize(view.content_for(:page_title))).to eql('You cannot register Jane Smith') }
  end

  it "displays the cannot register mentor message" do
    expect(rendered).to have_content("Our records show that Jane Smith cannot be registered as a mentor.")
  end

  it "includes a link back to ECTs" do
    expect(rendered).to have_link("Back to ECTs", href: schools_ects_home_path)
  end
end
