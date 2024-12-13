RSpec.describe "schools/register_ect_wizard/start_date.html.erb" do
  let(:back_path) { schools_register_ect_wizard_email_address_path }
  let(:continue_path) { schools_register_ect_wizard_start_date_path }
  let(:step) { Schools::RegisterECTWizard::StartDateStep.new }
  let(:ect) { double(full_name: 'John Smith') }
  let(:title) { "What is the date #{ect.full_name} started or will start teaching as an ECT at your school?" }
  let(:wizard) { Schools::RegisterECTWizard::Wizard.new(current_step: :find_ect, store: {}) }

  it "sets the page title to 'What is the date John Smith started or will start teaching as an ECT at your school?'" do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "prefixes the page with 'Error:' when the start date value invalid" do
    assign(:wizard, wizard)
    assign(:ect, ect)

    wizard.valid_step?
    render

    expect(view.content_for(:page_title)).to start_with('Error:')
  end

  it 'includes a back button that links to the email step' do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the start date page' do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(rendered).to have_button('Continue')
  end
end
