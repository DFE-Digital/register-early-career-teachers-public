RSpec.describe "schools/register_ect_wizard/national_insurance_number.html.erb" do
  let(:store) { build(:session_repository, national_insurance_number: "1234567") }
  let(:wizard) do
    build(:register_ect_wizard, current_step: :national_insurance_number, store:)
  end

  before do
    assign(:wizard, wizard)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("We cannot find the ECT's details")
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
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_find_ect_path)
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_national_insurance_number_path}']")
  end
end
