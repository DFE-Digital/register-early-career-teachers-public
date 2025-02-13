RSpec.shared_examples "a programme type view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:ect) { wizard.ect }
  let(:title) { "What training programme will #{ect.full_name} follow?" }
  let(:school) { double('School', type_name: 'Other independent school', independent?: true) }
  let(:programme_type) { nil }
  let(:store) { FactoryBot.build(:session_repository, programme_type:, full_name: 'John Smith') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step:, store:, school:) }

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title to 'What training programme will John Smith follow?'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  context "when the programme type is invalid" do
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
end
