RSpec.describe "schools/register_ect_wizard/funding_ind_appropriate_body.html.erb" do
  let(:back_path) { schools_register_ect_wizard_start_date_path }
  let(:continue_path) { schools_register_ect_wizard_check_answers_path }
  let(:step) { Schools::RegisterECTWizard::FundingIndAppropriateBodyStep.new }
  let(:ect) { double(full_name: 'John Smith') }
  let(:title) { "Which appropriate body will be supporting #{ect.full_name}'s induction?" }
  let(:wizard) { Schools::RegisterECTWizard::Wizard.new(current_step: :find_ect, store: {}) }

  it "sets the page title to 'Which appropriate body will be supporting John Smith's induction?'" do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "prefixes the page with 'Error:' when the appropriate body value missing" do
    assign(:wizard, wizard)
    assign(:ect, ect)

    wizard.valid_step?
    render

    expect(view.content_for(:page_title)).to start_with('Error:')
  end

  it 'includes a back button that links to the start date step' do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the funding ind appropriate body page' do
    assign(:wizard, wizard)
    assign(:ect, ect)

    render

    expect(rendered).to have_button('Continue')
  end
end
