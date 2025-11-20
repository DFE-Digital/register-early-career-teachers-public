RSpec.describe "appropriate_bodies/claim_an_ect/find_ect/new.html.erb" do
  let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission) }

  expected_title = "Find an early career teacher's (ECT) record"
  it "sets the page title to '#{expected_title}'" do
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(expected_title))
  end

  it "includes a back button that links to the AB homepage" do
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: "/appropriate-body/teachers")
  end

  it "prefixes the page with 'Error:' when the pending induction submission isn't valid" do
    pending_induction_submission.errors.add(:base, "An error")

    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(view.content_for(:page_title)).to start_with("Error:")
  end

  it "renders an error summary when the pending induction submission is invalid" do
    pending_induction_submission.errors.add(:base, "An error")

    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
  end

  describe "test guidance" do
    let(:current_user) { double(appropriate_body_user?: true, school_user?: false) }

    before do
      allow(Current).to receive(:user).and_return(current_user)
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
    end

    it "renders" do
      assign(:pending_induction_submission, pending_induction_submission)

      render

      expect(view.content_for(:test_guidance)).to have_text("Information to review this journey")
      expect(view.content_for(:test_guidance)).to have_text("Claimed by")
      expect(view.content_for(:test_guidance)).to have_table
    end
  end
end
