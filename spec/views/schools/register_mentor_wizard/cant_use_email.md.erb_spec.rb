RSpec.describe 'schools/register_mentor_wizard/cant_use_email.md.erb' do
  let(:title) { 'This email is already in use for a different ECT or mentor' }
  let(:back_path) { schools_register_mentor_wizard_find_mentor_path }

  before { render }

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it 'includes a back button that links to find-mentor page of the journey' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a try another email button that links to the find mentor page' do
    expect(rendered).to have_link('Try another email', href: back_path)
  end
end
