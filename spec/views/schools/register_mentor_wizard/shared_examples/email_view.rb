RSpec.shared_examples "an email address step view" do |current_step:, back_path:, back_step_name:, continue_path:, continue_step_name:|
  let(:mentor) { wizard.mentor }
  let(:email) { nil }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step:, store:) }
  let(:store) do
    FactoryBot.build(:session_repository,
      trn: "1234567",
      trs_first_name: "John",
      trs_last_name: "Waters",
      trs_date_of_birth: "1950-01-01",
      change_name: "yes",
      corrected_name: "Jim Waters",
      email:)
  end

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
  end

  context "page title" do
    before { render }

    it { expect(sanitize(view.content_for(:page_title))).to eql("What is Jim Waters's email address?") }
  end

  context "when the email is invalid" do
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

  it "includes a back button that targets #{back_step_name} page" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: send(back_path))
  end

  it "includes a continue button that posts to the #{continue_step_name} page" do
    render

    expect(rendered).to have_button("Continue")
    expect(rendered).to have_selector("form[action='#{send(continue_path)}']")
  end
end
