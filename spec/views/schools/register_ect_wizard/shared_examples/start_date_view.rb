RSpec.shared_examples "a start date view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:ect) { wizard.ect }
  let(:title) { "What is the date #{ect.full_name} started or will start teaching as an ECT at your school?" }
  let(:start_date) { nil }
  let(:store) { FactoryBot.build(:session_repository, start_date:, full_name: 'John Smith') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step:, store:) }

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title to 'What is the date John Smith started or will start teaching as an ECT at your school?'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  context "when the start date is invalid" do
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

  it "includes a back button that targets #{back_step_name} page" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: send(back_path))
  end

  it "includes a continue button that posts to the #{continue_step_name} page" do
    render

    expect(rendered).to have_button('Continue')
    expect(rendered).to have_selector("form[action='#{send(continue_path)}']")
  end

  it 'includes a start date field hint with the current year' do
    render

    expect(rendered).to have_content("For example, 9 #{Date.current.year}")
  end
end
