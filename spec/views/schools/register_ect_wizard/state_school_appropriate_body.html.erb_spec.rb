RSpec.describe "schools/register_ect_wizard/state_school_appropriate_body.html.erb" do
  let(:ect) { double(full_name: 'John Smith') }

  let(:wizard) do
    Schools::RegisterECTWizard::Wizard.new(current_step: :state_school_appropriate_body, store: {})
  end

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("Which appropriate body will be supporting John Smith's induction?")
  end

  context 'when the form is invalid' do
    before do
      wizard.valid_step?
      render
    end

    it "prefixes the page with 'Error:'" do
      expect(view.content_for(:page_title)).to start_with('Error:')
    end

    it 'renders an error summary' do
      expect(view.content_for(:error_summary)).to have_css('.govuk-error-summary')
    end
  end

  it 'includes a back link' do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_working_pattern_path)
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_state_school_appropriate_body_path}']")
  end
end
