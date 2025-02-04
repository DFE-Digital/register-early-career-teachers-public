RSpec.describe "schools/register_mentor_wizard/email_address.html.erb" do
  let(:back_path) { schools_register_mentor_wizard_review_mentor_details_path }
  let(:continue_path) { schools_register_mentor_wizard_email_address_path }
  let(:mentor) { wizard.mentor }
  let(:title) { "What is Jim Waters's email address?" }
  let(:email) { nil }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :email_address, store:) }
  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: "1234567",
                     trs_first_name: "John",
                     trs_last_name: "Waters",
                     trs_date_of_birth: "1950-01-01",
                     corrected_name: "Jim Waters",
                     email:)
  end

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

  describe "back link" do
    before { render }

    context "when not checking answers" do
      it 'targets review mentor details page' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
      end
    end

    context "when checking answers" do
      let(:email) { 'foo@example.com' }
      let(:back_path) { schools_register_mentor_wizard_check_answers_path }

      it 'targets check your answers page' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
      end
    end
  end

  it 'includes a continue button that posts to the email address page' do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{continue_path}']")
  end
end
