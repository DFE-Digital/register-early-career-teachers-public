RSpec.shared_examples "a state school appropriate body view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:ect) { wizard.ect }
  let(:title) { "Which appropriate body will be supporting #{ect.full_name}'s induction?" }
  let(:appropriate_body_name) { nil }
  let(:store) { FactoryBot.build(:session_repository, appropriate_body_name:, full_name: 'John Smith') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step:, store:) }

  before do
    assign(:wizard, wizard)
    assign(:ect, ect)
  end

  it "sets the page title to 'Which appropriate body will be supporting John Smith's induction?'" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  context "when the appropriate body name is invalid" do
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
