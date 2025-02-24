RSpec.describe "schools/register_ect_wizard/start_date.html.erb" do
  let(:ect) { double(full_name: 'John Smith') }

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :start_date, store: {})
  end

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("What is the date John Smith started or will start teaching as an ECT at your school?")
  end

  it "prefixes the page with 'Error:' when invalid" do
    wizard.valid_step?
    render
    expect(view.content_for(:page_title)).to start_with('Error:')
  end

  it 'includes a back link' do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_email_address_path)
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_start_date_path}']")
  end

  it 'includes a start date field hint with the current year' do
    render
    expect(rendered).to have_content("For example, 9 #{Date.current.year}")
  end
end
