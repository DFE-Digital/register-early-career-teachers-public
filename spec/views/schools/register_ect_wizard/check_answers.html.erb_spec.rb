RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:ect) do
    double('ECT',
           full_name: 'John Doe',
           trn: '123456',
           email: 'foo@bar.com',
           govuk_date_of_birth: '12 January 1931',
           start_date: 'September 2022',
           formatted_programme_type: 'School-led',
           formatted_appropriate_body_name: 'Teaching Regulation Agency',
           formatted_working_pattern: 'Full time')
  end
  let(:title) { "Check your answers before submitting" }
  let(:back_path) { schools_register_ect_wizard_programme_type_path }
  let(:continue_path) { schools_register_ect_wizard_check_answers_path }
  let(:wizard) { Schools::RegisterECTWizard::Wizard.new(current_step: :check_answers, store: {}) }

  before do
    assign(:ect, ect)
    assign(:wizard, wizard)
  end

  it "sets the page title to 'Check your answers before submitting'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it 'includes a back button that links to the email address step' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the check answers page' do
    render

    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{continue_path}']")
  end
end
