RSpec.describe "schools/register_mentor_wizard/email_address.html.erb" do
  let(:back_path) { schools_register_mentor_wizard_review_mentor_details_path }
  let(:continue_path) { schools_register_mentor_wizard_email_address_path }
  let(:mentor) { wizard.mentor }
  let(:title) { "What is Jim Waters's email address?" }
  let(:store) { double(trs_first_name: "John", trs_last_name: "Waters", corrected_name: "Jim Waters") }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :email_address, store:) }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
  end

  it "sets the page title to 'What is Jim Waters's email address'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  context "when the email is invalid" do
    before do
      wizard.valid_step?
      render
    end
    it "prefixes the page with 'Error:' when the email is invalid" do
      expect(view.content_for(:page_title)).to start_with('Error:')
    end

    it 'renders an error summary when the email is invalid' do
      expect(view.content_for(:error_summary)).to have_css('.govuk-error-summary')
    end
  end

  it 'includes a back button that links to check mentor details of the journey' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the email address page' do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{continue_path}']")
  end
end
