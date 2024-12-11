RSpec.describe "schools/mentorships/confirmation.md.erb" do
  let(:ect_name) { "Michale Dixon" }
  let(:mentor_name) { 'Peter Times' }
  let(:title) { "You've assigned #{mentor_name} as a mentor" }
  let(:your_ects_path) { schools_ects_home_path }

  before do
    assign(:ect_name, ect_name)
    assign(:mentor_name, mentor_name)
  end

  it "sets the page title to 'You've assigned <mentor name> as a mentor'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it 'includes no back button' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'includes a button that links to the school home page' do
    render

    expect(rendered).to have_link('Back to your ECTs', href: your_ects_path)
  end
end
