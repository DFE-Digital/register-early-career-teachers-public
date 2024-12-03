RSpec.describe "schools/register_mentor/find_mentor.html.erb" do
  let(:back_path) { schools_register_mentor_start_path }
  let(:continue_path) { schools_register_mentor_find_mentor_path }
  let(:title) { "Find a mentor" }
  let(:wizard) { Schools::RegisterMentor::Wizard.new(current_step: :find_mentor, store: {}) }

  before do
    assign(:wizard, wizard)
  end

  it "sets the page title to 'Find a mentor'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "prefixes the page with 'Error:' when the trn or date of birth values are invalid" do
    wizard.valid_step?
    render

    expect(view.content_for(:page_title)).to start_with('Error:')
  end

  it 'renders an error summary when the trn or date of birth is invalid' do
    wizard.valid_step?
    render

    expect(view.content_for(:error_summary)).to have_css('.govuk-error-summary')
  end

  it 'includes a back button that links to the start page of the register mentor journey' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that posts to the find mentor page' do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{continue_path}']")
  end

  it "includes a link to 'They do not have a TRN' a TRN" do
    render

    expect(rendered).to have_link('They do not have a TRN', href: schools_register_mentor_cannot_without_trn_path)
  end
end
