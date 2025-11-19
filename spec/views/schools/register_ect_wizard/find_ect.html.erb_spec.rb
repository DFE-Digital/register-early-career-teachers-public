RSpec.describe "schools/register_ect_wizard/find_ect.html.erb" do
  let(:store) { FactoryBot.build(:session_repository, trn: "1234567") }
  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :find_ect, store:)
  end

  before do
    assign(:wizard, wizard)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("Find an ECT")
  end

  context "when the form is invalid" do
    before do
      wizard.valid_step?
      render
    end

    it "prefixes the page with 'Error:'" do
      expect(view.content_for(:page_title)).to start_with("Error:")
    end

    it "renders an error summary" do
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end

  it "includes a back link" do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: schools_register_ect_wizard_start_path)
  end

  it "includes a continue button" do
    render
    expect(rendered).to have_button("Continue")
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_find_ect_path}']")
  end

  describe "test guidance" do
    let(:current_user) { double(appropriate_body_user?: false, school_user?: true) }

    before do
      allow(Current).to receive(:user).and_return(current_user)
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
    end

    it "renders" do
      render
      expect(view.content_for(:test_guidance)).to have_text("Information to review this journey")
      expect(view.content_for(:test_guidance)).to have_text("Registered with")
      expect(view.content_for(:test_guidance)).to have_table
    end
  end
end
