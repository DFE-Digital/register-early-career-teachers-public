RSpec.describe "schools/register_ect_wizard/lead_provider.html.erb" do
  let(:ect) { double(full_name: 'John Smith') }

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :lead_provider, store: {})
  end

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("Which lead provider will be training John Smith?")
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
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_programme_type_path)
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_lead_provider_path}']")
  end
end
