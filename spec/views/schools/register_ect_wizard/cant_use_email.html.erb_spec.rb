RSpec.describe 'schools/register_ect_wizard/cant_use_email.html.erb' do
  let(:back_path) { schools_register_ect_wizard_email_address_path }
  let(:store) { FactoryBot.build(:session_repository, trs_first_name: "John", trs_last_name: "Waters", email: 'a@email.com') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :cant_use_email, store:) }

  before do
    assign(:wizard, wizard)
    render
  end

  context 'page title' do
    it { expect(sanitize(view.content_for(:page_title))).to eql('This email is already in use for a different ECT or mentor') }
  end

  it 'includes a back button that links to find-mentor page of the journey' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a try another email button that links to the find mentor page' do
    expect(rendered).to have_link('Try another email', href: back_path)
  end
end
