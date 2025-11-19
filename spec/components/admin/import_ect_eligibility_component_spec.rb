RSpec.describe Admin::ImportECTEligibilityComponent, type: :component do
  subject(:component) do
    described_class.new(pending_induction_submission:)
  end

  let(:trs_induction_status) { "None" }
  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      trs_first_name: "Troy",
                      trs_last_name: "McClure",
                      trs_induction_status:)
  end

  before { render_inline(component) }

  context "when status is None" do
    it "does not render" do
      expect(rendered_content).to be_blank
    end
  end

  context "when status is ReadyToComplete" do
    let(:trs_induction_status) { "ReadyToComplete" }

    it "does not render" do
      expect(rendered_content).to be_blank
    end
  end

  context "when status is InProgress" do
    let(:trs_induction_status) { "InProgress" }

    it "does not render" do
      expect(rendered_content).to be_blank
    end
  end

  context "when status is Exempt" do
    let(:trs_induction_status) { "Exempt" }

    it "renders exemption warning" do
      expect(page).to have_text("You cannot register Troy McClure")
      expect(page).to have_text("Our records show that Troy McClure is exempt from completing their induction.")
      expect(page).to have_link("Import another ECT", href: "/admin/import-ect/find-ect/new")
    end
  end

  context "when status is Passed" do
    let(:trs_induction_status) { "Passed" }

    it "renders already passed warning" do
      expect(page).to have_text("You cannot register Troy McClure")
      expect(page).to have_text("Our records show that Troy McClure has already passed their induction.")
      expect(page).to have_link("Import another ECT", href: "/admin/import-ect/find-ect/new")
    end
  end

  context "when status is Failed" do
    let(:trs_induction_status) { "Failed" }

    it "renders already failed warning" do
      expect(page).to have_text("You cannot register Troy McClure")
      expect(page).to have_text("Our records show that Troy McClure has already failed their induction.")
      expect(page).to have_link("Import another ECT", href: "/admin/import-ect/find-ect/new")
    end
  end

  context "when status is FailedInWales" do
    let(:trs_induction_status) { "FailedInWales" }

    it "renders already failed warning" do
      expect(page).to have_text("You cannot register Troy McClure")
      expect(page).to have_text("Our records show that Troy McClure has already failed their induction.")
      expect(page).to have_link("Import another ECT", href: "/admin/import-ect/find-ect/new")
    end
  end

  context "when QTS is not awarded" do
    let(:pending_induction_submission) do
      FactoryBot.create(:pending_induction_submission,
                        trs_first_name: "Troy",
                        trs_last_name: "McClure",
                        trs_qts_awarded_on: nil)
    end

    it "renders no QTS warning" do
      expect(page).to have_text("You cannot register Troy McClure")
      expect(page).to have_text("Our records show that Troy McClure does not have their qualified teacher status (QTS).")
      expect(page).to have_link("Import another ECT", href: "/admin/import-ect/find-ect/new")
    end
  end
end
