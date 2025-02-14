RSpec.describe "schools/register_ect_wizard/programme_type.html.erb" do
  let(:school) { double('School', type_name: 'Other independent school', independent?: true) }

  let(:ect) { double(full_name: 'John Smith') }

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :programme_type, store: {}, school:)
  end

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("What training programme will John Smith follow?")
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
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_independent_school_appropriate_body_path)
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_programme_type_path}']")
  end
end
