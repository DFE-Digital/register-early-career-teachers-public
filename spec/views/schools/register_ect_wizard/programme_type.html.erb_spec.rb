RSpec.describe "schools/register_ect_wizard/programme_type.html.erb" do
  let(:back_path) { schools_register_ect_wizard_email_address_path }
  let(:continue_path) { schools_register_ect_wizard_check_answers_path }
  let(:step) { Schools::RegisterECTWizard::FindECTStep.new }
  let(:ect) { double(full_name: 'John Smith') }
  let(:title) { "What training programme will #{ect.full_name} follow?" }
  let(:wizard) { Schools::RegisterECTWizard::Wizard.new(current_step: :programme_type, store: {}) }

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title to 'What training programme will John Smith follow?'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "prefixes the page with 'Error:' when the programme type is not selected" do
    wizard.valid_step?
    render

    expect(view.content_for(:page_title)).to start_with('Error:')
  end

  it 'includes a back button that links to the start page of the register ECT journey' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the programme type page' do
    render

    expect(rendered).to have_button('Continue')
  end
end
