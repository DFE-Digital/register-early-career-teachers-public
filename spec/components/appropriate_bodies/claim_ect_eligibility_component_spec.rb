RSpec.describe AppropriateBodies::ClaimECTEligibilityComponent, type: :component do
  subject(:component) do
    described_class.new(pending_induction_submission:, appropriate_body:, teacher:)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:trs_induction_status) { "None" }
  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
      trs_first_name: "John",
      trs_last_name: "Doe",
      trs_induction_status:)
  end

  context "without teacher" do
    let(:teacher) { nil }

    before { render_inline(component) }

    context "when status is None" do
      it "renders the claim induction CTA" do
        expect(page).to have_button("Claim induction")
        expect(page).not_to have_text("You cannot register John Doe")
        expect(page).not_to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
      end
    end

    context "when status is ReadyToComplete" do
      let(:trs_induction_status) { "ReadyToComplete" }

      it "renders the claim induction CTA" do
        expect(page).to have_button("Claim induction")
        expect(page).not_to have_text("You cannot register John Doe")
        expect(page).not_to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
      end
    end

    context "when status is InProgress" do
      let(:trs_induction_status) { "InProgress" }

      it "renders the claim induction CTA" do
        expect(page).to have_button("Claim induction")
        expect(page).not_to have_text("You cannot register John Doe")
        expect(page).not_to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
      end
    end

    context "when status is Exempt" do
      let(:trs_induction_status) { "Exempt" }

      it "does not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe is exempt from completing their induction.")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end

    context "when status is Passed" do
      let(:trs_induction_status) { "Passed" }

      it "does not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe has already passed their induction.")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end

    context "when status is Failed" do
      let(:trs_induction_status) { "Failed" }

      it "does not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe has already failed their induction.")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end

    context "when status is FailedInWales" do
      let(:trs_induction_status) { "FailedInWales" }

      it "does not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe has already failed their induction.")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end

    context "when QTS is not awarded" do
      let(:pending_induction_submission) do
        FactoryBot.create(:pending_induction_submission,
          trs_first_name: "John",
          trs_last_name: "Doe",
          trs_qts_awarded_on: nil)
      end

      it "does not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe does not have their qualified teacher status (QTS).")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end
  end

  context "with a registered teacher" do
    let(:teacher) { FactoryBot.create(:teacher) }

    context "and the teacher is claimed by another appropriate body" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        render_inline(component)
      end

      it "oes not render the claim induction CTA" do
        expect(page).to have_text("You cannot register John Doe")
        expect(page).to have_text("Our records show that John Doe is completing their induction with another appropriate body")
        expect(page).to have_link("Find and claim another ECT", href: "/appropriate-body/claim-an-ect/find-ect/new")
        expect(page).not_to have_button("Claim induction")
      end
    end
  end
end
