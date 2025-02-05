RSpec.describe "schools/register_mentor_wizard/cannot_mentor_themself.md.erb" do
  let(:back_path) { schools_register_mentor_wizard_find_mentor_path }
  let(:title) { 'You cannot assign an ECT as their own mentor' }

  before do
    render
  end

  it "sets the page title to 'You cannot assign an ECT as their own mentor'" do
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it 'includes a back button that links to find-mentor page of the journey' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a button to assign a different mentor to the ECT' do
    expect(rendered).to have_link('Assign a different mentor', href: back_path)
  end
end
